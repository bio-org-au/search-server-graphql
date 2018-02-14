# frozen_string_literal: true

# Class for the result of a taxonomy search
class Taxonomy::Search::Result
  attr_reader :id, :full_name, :simple_name, :name_status_name,
              :reference_citation
  def initialize(h)
    @id = h[:id]
    @full_name = h[:full_name]
    @simple_name = h[:simple_name]
    @name_status_name = h[:name_status_name]
    @reference_citation = h[:reference_citation]
    @instance_id = h[:instance_id]
  end

  def taxon_details
    Taxonomy::Search::Details.new(@instance_id)
  end
end
