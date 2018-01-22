# frozen_string_literal: true

# Class for name_history_type
class Reference::Search::History
  attr_reader :name_usages, :synonym_bunch

  def initialize(name_id)
    Rails.logger.debug('Name::Search::History initialize')
    @name = Name.find(name_id)
    raw_results = Name::Search::UsageQuery.new(name_id).results
    instance_ids = raw_results.map(&:instance_id)
    @synonym_bunch = Name::Search::Synonym::BunchQuery.new(instance_ids)
    unless @synonym_bunch.results.empty?
      @name_usages = raw_results.collect do |usage|
        Name::Search::Usage.new(usage, @synonym_bunch)
      end
    end
  end
end
