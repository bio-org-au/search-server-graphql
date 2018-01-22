# frozen_string_literal: true

# For a given instance ID, retrieve a set of ordered
# synonyms
class Taxonomy::Search::Synonyms < Array
  attr_reader :instance_id
  def initialize(instance_id)
    @instance_id = instance_id
    instance = Instance.find(instance_id)
    instance.instance_as_synonyms.each do |synonym|
      push Taxonomy::Search::Synonym.new(synonym)
    end
  end
end
