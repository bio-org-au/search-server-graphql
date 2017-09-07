# frozen_string_literal: true

# For a given instance ID, retrieve a set of ordered
# synonymy instance results suitable for displaying within a name usage.
class SynonymPick
  attr_reader :results, :id
  def initialize(instance_id, synonym_bunch)
    @instance_id = instance_id
    @synonym_bunch = synonym_bunch
    @results = []
    build_results
  end

  def build_results
    @synonym_bunch.results.each do |result|
      if result[:cited_by_id] == @instance_id
        Rails.logger.debug('picking a has')
        @results.push(Synonym.new(result, 'has'))
      end
      if result[:instance_id] == @instance_id
        Rails.logger.debug('picking an of')
        @results.push(Synonym.new(result, 'of'))
      end
    end
  end
end
