# frozen_string_literal: true

# Rails model
class Site < ActiveRecord::Base
  self.table_name = 'site'
  self.primary_key = 'id'

  has_many :resources
end
