# frozen_string_literal: true

# Rails model
class InstanceType < ActiveRecord::Base
  self.table_name = "instance_type"
  self.primary_key = "id"
  has_many :instances
  has_many :synonyms

  def primaries_first
    primary_instance ? "A" : "B"
  end

  def primary?
    primary_instance
  end

  def protologue?
    protologue
  end

  def misapplied?
    misapplied == true
  end

  def doubtful?
    doubtful == true
  end

  def pro_parte?
    pro_parte == true
  end
end
