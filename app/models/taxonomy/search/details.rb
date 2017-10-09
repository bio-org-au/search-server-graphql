# frozen_string_literal: true

# For a given instance ID, retrieve a set of ordered
# details
class Taxonomy::Search::Details
  attr_reader :instance_id
  def initialize(instance_id)
    @instance = Instance.find(instance_id)
  end

  def taxon_synonyms
    Taxonomy::Search::Synonyms.new(@instance.id)
  end

  def taxon_distribution
    @instance.apc_distribution
  end

  def taxon_comment
    @instance.apc_comment
  end
end
