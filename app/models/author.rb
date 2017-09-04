class Author < ApplicationRecord
  self.table_name = "author"
  self.primary_key = "id"
  has_many :references
end
