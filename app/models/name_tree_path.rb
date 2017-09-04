# frozen_string_literal: true

# Rails model
class NameTreePath < ActiveRecord::Base
  self.table_name = "name_tree_path"
  self.primary_key = "id"

  belongs_to :name
  belongs_to :apni_name_tree_path, class_name: "Name"
  belongs_to :apni_tree_arrangement,
             (lambda do
                where(label: ShardConfig.name_tree_label)
              end),
             class_name: "TreeArrangement",
             foreign_key: "tree_id"
end

