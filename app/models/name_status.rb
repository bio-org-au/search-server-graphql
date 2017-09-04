# frozen_string_literal: true

# Rails model
class NameStatus < ActiveRecord::Base
  self.table_name = "name_status"
  self.primary_key = "id"
  has_many :names
  has_many :accepted_synonyms

  def show?
    name != "legitimate" &&
      name[0] != "["
  end

  def self.show?(status_name)
    status_name != "legitimate" &&
      status_name[0] != "["
  end

  def name_to_show
    ", #{name}" if show?
  end
end
