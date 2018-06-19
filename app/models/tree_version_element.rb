# frozen_string_literal: true

# Rails model for Tree Version Element
class TreeVersionElement < ApplicationRecord
  self.table_name = 'tree_version_element'
  self.primary_key = 'element_link'
  belongs_to :tree_version
  belongs_to :tree_element
end
