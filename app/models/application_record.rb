# Rails model super class
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
