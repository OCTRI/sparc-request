class CatalogManager < ActiveRecord::Base
  #Version.primary_key = 'id'
  #has_paper_trail

  belongs_to :organization
  belongs_to :identity

  attr_accessible :identity_id
  attr_accessible :organization_id
  attr_accessible :edit_historic_data
end

