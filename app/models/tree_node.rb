# frozen_string_literal: true

# Rails model
class TreeNode < ApplicationRecord
  self.table_name = 'tree_node'
  self.primary_key = 'id'
  has_many :references
  has_many :authors
  belongs_to :name
  belongs_to :tree_arrangement
end
