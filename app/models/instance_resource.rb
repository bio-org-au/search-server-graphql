# frozen_string_literal: true

# Rails model
class InstanceResource < ActiveRecord::Base
  self.table_name = 'instance_resource'
  self.primary_key = 'instance_id, resource_id'

  belongs_to :instance
  belongs_to :resource
  
end
