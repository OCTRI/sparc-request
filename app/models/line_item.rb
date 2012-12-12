class LineItem < ActiveRecord::Base
  #Version.primary_key = 'id'
  #has_paper_trail

  belongs_to :service_request
  belongs_to :service, :include => [:pricing_maps, :organization]
  belongs_to :sub_service_request
  has_many :visits, :dependent => :destroy, :order => 'position'
  has_many :fulfillments, :dependent => :destroy

  attr_accessible :service_request_id
  attr_accessible :sub_service_request_id
  attr_accessible :service_id
  attr_accessible :optional
  attr_accessible :quantity
  attr_accessible :subject_count
  attr_accessible :complete_date
  attr_accessible :in_process_date
  attr_accessible :units_per_quantity

  # TODO: order by date/id instead of just by date?
  default_scope :order => 'id ASC'

  def applicable_rate
    pricing_map         = self.service.displayed_pricing_map
    pricing_setup       = self.service.organization.current_pricing_setup
    funding_source      = self.service_request.protocol.funding_source_based_on_status
    selected_rate_type  = pricing_setup.rate_type(funding_source)
    applied_percentage  = pricing_setup.applied_percentage(selected_rate_type)
    rate                = pricing_map.applicable_rate(selected_rate_type, applied_percentage)
    return rate
  end

  # Returns the cost per unit based on a quantity (usually just the quantity on the line_item)
  def per_unit_cost quantity_total=self.quantity
    if quantity_total == 0 || quantity_total.nil?
      0
    else
      units_per_package = self.units_per_package
      packages_we_have_to_get = (quantity_total.to_f / units_per_package.to_f).ceil
      total_cost = packages_we_have_to_get.to_f * self.applicable_rate.to_f
      ret_cost = total_cost / quantity_total.to_f
      unless self.units_per_quantity.blank?
        ret_cost = ret_cost * self.units_per_quantity
      end
      return ret_cost
    end
  end

  def units_per_package
    unit_factor = self.service.displayed_pricing_map.unit_factor
    units_per_package = unit_factor || 1
    return units_per_package
  end

  def quantity_total
    # quantity_total = self.visits.map {|x| x.research_billing_qty}.inject(:+) * self.subject_count
    result = self.connection.execute("SELECT SUM(research_billing_qty) FROM visits WHERE line_item_id=#{self.id}") # TODO: sanitize
    quantity_total = result.to_a[0][0] || 0
    return quantity_total * self.subject_count
  end

  # Returns a hash of subtotals for the visits in the line item.
  # Visit totals depend on the quantities in the other visits, so it would be clunky
  # to compute one visit at a time
  def per_subject_subtotals(visits=self.visits)
    totals = { }
    quantity_total = quantity_total()
    per_unit_cost = per_unit_cost(quantity_total)

    visits.each do |visit|
      totals[visit.id.to_s] = visit.cost(per_unit_cost)
    end

    return totals
  end

  # Determine the direct costs for a visit-based service for one subject
  def direct_costs_for_visit_based_service_single_subject
    # totals_array = self.per_subject_subtotals(visits).values.select {|x| x.class == Float}
    # subject_total = totals_array.empty? ? 0 : totals_array.inject(:+)
    result = self.connection.execute("SELECT SUM(research_billing_qty) FROM visits WHERE line_item_id=#{self.id} AND research_billing_qty >= 1")
    research_billing_qty_total = result.to_a[0][0] || 0
    subject_total = research_billing_qty_total * per_unit_cost(quantity_total())

    subject_total
  end

  # Determine the direct costs for a visit-based service
  def direct_costs_for_visit_based_service
    self.subject_count * self.direct_costs_for_visit_based_service_single_subject
  end

  # Determine the direct costs for a one-time-fee service
  def direct_costs_for_one_time_fee
    num = self.quantity || 0.0
    num * self.per_unit_cost
  end

  # Determine the indirect cost rate related to a particular line item
  def indirect_cost_rate
    self.service_request.protocol.indirect_cost_rate.to_f / 100
  end

  # Determine the indirect cost rate for a visit-based service for one subject
  def indirect_costs_for_visit_based_service_single_subject
    self.direct_costs_for_visit_based_service_single_subject * self.indirect_cost_rate
  end

  # Determine the indirect costs for a visit-based service
  def indirect_costs_for_visit_based_service
    self.direct_costs_for_visit_based_service * self.indirect_cost_rate
  end

  # Determine the indirect costs for a one-time-fee service
  def indirect_costs_for_one_time_fee
    if self.service.displayed_pricing_map.exclude_from_indirect_cost
      return 0
    else
      self.direct_costs_for_one_time_fee * self.indirect_cost_rate
    end
  end

  # Add a new visit.  Returns the new Visit upon success or false upon
  # error.
  def add_visit position=nil
    self.visits.create(position: position)
  end

  def remove_visit position
    visit = self.visits.find_by_position(position)
    # Move visit to the end by position, re-number other visits
    visit.move_to_bottom
    # Must reload to refresh other visit positions, otherwise two 
    # records with same postion will exist
    self.reload
    visit.delete
  end

  # In fulfillment, when you change the service on an existing line item
  def switch_to_one_time_fee
    result = self.transaction do
      self.quantity = 1 unless self.quantity  
      self.units_per_quantity unless self.units_per_quantity
      self.visits.each {|x| x.destroy}
      self.save or raise ActiveRecord::Rollback
    end

    if result
      return true
    else
      self.reload
      return false
    end
  end

  # In fulfillment, when you change the service on an existing line item
  def switch_to_per_patient_per_visit
    result = self.transaction do
      self.service_request.insure_visit_count()
      (self.service_request.visit_count - visits.size).times do #somehow service request visit count is higher so create
        visits.create!
      end
      (visits.size - self.service_request.visit_count).times do #somehow service request visit count is lower so delete
        visits.last.destroy
      end
      self.service_request.insure_subject_count()
      self.save or raise ActiveRecord::Rollback
    end

    if result
      return true
    else
      self.reload
      return false
    end
  end

end

class LineItem::ObisEntitySerializer
  def as_json(line_item, options = nil)
    h = {
      'optional'                => line_item.optional,
      'quantity'                => line_item.quantity,
      'sub_service_request_id'  => line_item.sub_service_request.ssr_id,
      'visits'                  => line_item.visits.as_json(options),
      'fulfillment'             => line_item.fulfillments.as_json(options), # sic
    }

    optional = {
      'service_id'              => line_item.service.obisid,
      'subject_count'           => line_item.subject_count,
      'in_process_date'         => line_item.in_process_date.try(:strftime, '%Y-%m-%d'),
      'complete_date'           => line_item.complete_date.try(:strftime, '%Y-%m-%d'),
    }

    optional.delete_if { |k, v| v.nil? }

    h.update(optional)

    return h
  end

  def update_from_json(line_item, h, options = nil)
    service = Service.find_by_obisid(h['service_id'])
    raise ArgumentError, "Could not find service with obisid #{h['service_id']}" if not service

    service_request = line_item.service_request
    ssr = service_request.sub_service_requests.find_by_ssr_id(
        h['sub_service_request_id'])

    raise ArgumentError, "Could not find ssr with ssr_id #{h['sub_service_request_id']}" if not ssr

    line_item.update_attributes!(
        optional:                  h['optional'],
        quantity:                  h['quantity'],
        sub_service_request_id:    ssr.id,
        fulfillments:              h['fulfillments'],
        service_id:                service.id,
        subject_count:             h['subject_count'],
        in_process_date:           legacy_parse_date(h['in_process_date']),
        complete_date:             legacy_parse_date(h['complete_date']))

    # Delete all visits for the line item; they will be re-created in
    # the next step.
    line_item.visits.each do |visit|
      visit.destroy()
    end

    # Create a new visit for each one that is passed in.
    (h['visits'] || [ ]).each do |h_visit|
      visit = line_item.visits.create()
      visit.update_from_json(h_visit, options)
    end

    # Delete all fulfillments for the line item; they will be re-created in
    # the next step.
    line_item.fulfillments.each do |fulfillment|
      fulfillment.destroy()
    end

    # Create a new fulfillment for each one that is passed in.
    (h['fulfillment'] || [ ]).each do |h_fulfillment|
      fulfillment = line_item.fulfillments.create()
      fulfillment.update_from_json(h_fulfillment, options)
    end
  end
end

class LineItem
  include JsonSerializable
  json_serializer :obisentity, ObisEntitySerializer
end

