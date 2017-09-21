# frozen_string_literal: true

# Tree Arrangement model
class TreeArrangement < ActiveRecord::Base
  self.table_name = 'tree_arrangement'
  self.primary_key = 'id'

  def self.default_name_tree_id
    @default_name_tree_id ||= TreeArrangement.where(label: 'APNI').first.id
  end
end
