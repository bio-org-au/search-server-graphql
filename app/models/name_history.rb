# frozen_string_literal: true

# Class for name_history_type
class NameHistory
  attr_reader :name_usages, :synonym_bunch

  def initialize(name_id)
    Rails.logger.debug('NameHistory initialize')
    @name = Name.find(name_id)
    raw_results = NameUsageQuery.new(name_id).results
    Rails.logger.debug(raw_results.class)
    Rails.logger.debug(raw_results.class)
    Rails.logger.debug(raw_results.class)
    instance_ids = raw_results.map(&:instance_id)
    Rails.logger.debug(instance_ids.join(','))
    @synonym_bunch = SynonymBunchQuery.new(instance_ids)
    unless @synonym_bunch.results.empty?
    end
    @name_usages = raw_results.collect do |usage|
      NameUsage.new(usage, @synonym_bunch)
    end
  end
end
