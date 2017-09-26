# frozen_string_literal: true

# Rails model
class Author < ApplicationRecord
  self.table_name = 'author'
  self.primary_key = 'id'
  has_many :references
  has_many :authors
end
