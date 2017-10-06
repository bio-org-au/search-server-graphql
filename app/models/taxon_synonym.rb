# frozen_string_literal: true

# Attributes for synonym type.
class TaxonSynonym
  attr_reader :id, :full_name, :instance_type, :page, :label,
              :page, :page_qualifier

  def initialize(instance)
    @instance = instance
  end

  def id
    @instance.id
  end

  def name_id
    @instance.name_id
  end

  def full_name
    @instance.name.full_name
  end
end
