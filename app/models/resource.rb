# frozen_string_literal: true

# Rails model
class Resource < ActiveRecord::Base
  self.table_name = 'resource'
  self.primary_key = 'id'

  has_many :instance_resources
  belongs_to :site
end
