# frozen_string_literal: true

# For a given instance ID, retrieve a set of ordered
# details
class TaxonDetails
  attr_reader :instance_id
  def initialize(instance_id)
    @instance_id = instance_id
  end

  def taxon_synonyms
    TaxonSynonyms.new(@instance_id)
  end
end
