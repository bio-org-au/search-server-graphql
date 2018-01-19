# frozen_string_literal: true

# Class for name_history_type
class Name::Search::History
  attr_reader :name_usages, :synonym_bunch

  def initialize(name_id)
    Rails.logger.debug('Name::Search::History initialize')
    @name = Name.find(name_id)
    usage_query_results = Name::Search::UsageQuery.new(name_id).results
    usage_query_results.each do |uqresult|
      Rails.logger.debug("uqresult[:accepted_tree_status]: #{uqresult[:accepted_tree_status]}")
    end
    usage_instance_ids = usage_query_results.map(&:instance_id)
    @synonym_bunch = Name::Search::Synonym::BunchQuery.new(usage_instance_ids)
    Rails.logger.debug("Building @name_usages ===========================")
    @name_usages = usage_query_results.collect do |usage_query_result|
      Rails.logger.debug("usage_query_result.class: #{usage_query_result.class}")
      Name::Search::Usage.new(usage_query_result, @synonym_bunch) unless usage_query_result.nil?
    end
    Rails.logger.debug("After building @name_usages ===========================")
    @name_usages.each do |name_usage|
      Rails.logger.debug("name_usage.accepted_tree_status: #{name_usage.accepted_tree_status}")
    end
  end
end
