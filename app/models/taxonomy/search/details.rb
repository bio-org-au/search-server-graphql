# frozen_string_literal: true

# For a given instance ID, retrieve a set of ordered
# details
class Taxonomy::Search::Details
  attr_reader :instance_id
  def initialize(instance_id)
    @instance_id = instance_id
  end

  def taxon_synonyms
    Taxonomy::Search::Synonyms.new(@instance_id)
  end
end
