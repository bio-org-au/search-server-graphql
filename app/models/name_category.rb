# frozen_string_literal: true

# Rails model
class NameCategory < ActiveRecord::Base
  self.table_name = 'name_category'
  self.primary_key = 'id'
  has_many :name_types
end
