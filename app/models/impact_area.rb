class ImpactArea < ActiveRecord::Base
  #Version.primary_key = 'id'
  #has_paper_trail

  belongs_to :protocol

  attr_accessible :protocol_id
  attr_accessible :name
  attr_accessible :new
  attr_accessible :position
  attr_accessor :new
  attr_accessor :position

  TYPES = {
    'pediatrics' => 'Pediatrics',
    'hiv_aids' => 'HIV/AIDS',
    'hypertension' => 'Hypertension',
    'stroke' => 'Stroke',
    'diabetes' => 'Diabetes',
    'cancer' => 'Cancer'
  }
end

