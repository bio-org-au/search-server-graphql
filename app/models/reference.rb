# frozen_string_literal: true

# Rails model
class Reference < ActiveRecord::Base
  self.table_name = 'reference'
  self.primary_key = 'id'
  # has_many :instances
  # has_many :synonyms
  # has_many :cites
  # has_many :name_or_synonyms
  # has_many :accepted_names
  # has_many :name_references
  belongs_to :author
  # belongs_to :reference_author, class_name: :author
end
