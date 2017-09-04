# frozen_string_literal: true

# Rails model
class NameType < ActiveRecord::Base
  self.table_name = "name_type"
  self.primary_key = "id"

  has_many :names
  belongs_to :name_category
  belongs_to :name_group
  scope :common_or_informal, -> { "where(name in ('common','informal'))" }
end

