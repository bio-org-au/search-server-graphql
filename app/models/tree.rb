# frozen_string_literal: true

# Tree model
class Tree < ActiveRecord::Base
  self.table_name = 'tree'
  self.primary_key = 'id'
  has_many :tree_versions, foreign_key: :tree_id
  scope :accepted, -> { where(accepted_tree: true) }

  belongs_to :current_tree_version, class_name: "TreeVersion",  foreign_key: :current_tree_version_id
end
