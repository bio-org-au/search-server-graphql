# frozen_string_literal: true

# Rails model
class NameTreePath < ActiveRecord::Base
  self.table_name = 'name_tree_path'
  self.primary_key = 'id'

  belongs_to :name
  belongs_to :family, class_name: 'Name', foreign_key: 'family_id'
  belongs_to :apni_name_tree_path, class_name: 'Name'
  belongs_to :apni_tree_arrangement,
             (lambda do
                where(label: ShardConfig.name_tree_label)
              end),
             class_name: 'TreeArrangement',
             foreign_key: 'tree_id'
  belongs_to :accepted_tree_arrangement,
             (lambda do
                where(label: ShardConfig.taxonomy_tree_key)
              end),
             class_name: 'TreeArrangement',
             foreign_key: 'tree_id'

  belongs_to :tree, class_name: 'TreeArrangement', foreign_key: 'tree_id'
  belongs_to :parent, class_name: "NameTreePath"
  has_many :children,
            class_name: "NameTreePath",
            foreign_key: "parent_id"
end
