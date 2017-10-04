# frozen_string_literal: true

# Tree Arrangement model
class TreeArrangement < ActiveRecord::Base
  self.table_name = 'tree_arrangement'
  self.primary_key = 'id'
  belongs_to :namespace
  has_many :name_tree_paths, foreign_key: :tree_id

  def self.default_name_tree_id
    @default_name_tree_id ||= TreeArrangement.where(label: 'APNI').first.id
  end
end
