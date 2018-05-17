# frozen_string_literal: true

# Class for name_history_type
class Name::Search::History
  attr_reader :name_usages, :synonym_bunch

  def initialize(name_id)
    @name = Name.find(name_id)
    ref_citations = Name::Search::UsageQuery.new(name_id).results
    usage_instance_ids = ref_citations.map(&:instance_id)
    @synonym_bunch = Name::Search::Synonym::BunchQuery.new(usage_instance_ids)
    @name_usages = ref_citations.collect do |ref_citation|
      Name::Search::Usage.new(ref_citation, @synonym_bunch) unless ref_citation.nil?
    end
  end
end


