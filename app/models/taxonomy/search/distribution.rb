# frozen_string_literal: true

# For a given instance ID, retrieve the distribution
class Taxonomy::Search::Distribution
  attr_reader :instance_id
  def initialize(instance_id)
    @instance_id = instance_id
    instance = Instance.find(instance_id)
    instance.instance_as_synonyms.each do |synonym|
      self.push Taxonomy::Search::Synonym.new(synonym)
    end
  end
end
