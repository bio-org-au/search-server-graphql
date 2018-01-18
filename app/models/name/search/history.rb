# frozen_string_literal: true

# Class for name_history_type
class Name::Search::History
  attr_reader :name_usages, :synonym_bunch

  def initialize(name_id)
    Rails.logger.debug('Name::Search::History initialize')
    @name = Name.find(name_id)
    raw_results = Name::Search::UsageQuery.new(name_id).results
    instance_ids = raw_results.map(&:instance_id)
    @synonym_bunch = Name::Search::Synonym::BunchQuery.new(instance_ids)
    unless @synonym_bunch.results.empty?
      Rails.logger.debug("Building @name_usages ===========================")
      @name_usages = raw_results.collect do |usage|
        Rails.logger.debug("usage.class: #{usage.class}")
        Name::Search::Usage.new(usage, @synonym_bunch)
      end
      Rails.logger.debug("After building @name_usages ===========================")
    end
  end
end
