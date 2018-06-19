# frozen_string_literal: true

# Rails model for Tree Version
class TreeVersion < ApplicationRecord
  self.table_name = 'tree_version'
  self.primary_key = 'id'
  belongs_to :tree
  has_many :tree_version_elements
  has_many :tree_elements, through: :tree_version_elements
end
