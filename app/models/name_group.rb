# frozen_string_literal: true

# Rails model
class NameGroup < ActiveRecord::Base
  self.table_name = 'name_group'
  self.primary_key = 'id'
  has_many :name_types
  has_many :name_statuses
  has_many :name_ranks
end
