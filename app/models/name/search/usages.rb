# frozen_string_literal: true

# Class for name_usages
class Name::Search::Usages
  attr_reader :name_usages

  def initialize(name_id)
    debug("For name: #{name_id}")
    prev_name_id =-1
    prev_ref_id = -1
    prev_type = 'not-one'
    prev_page = 'not-one'
    latest_usage = nil
    @name = Name.find(name_id)
    ref_citations = Name::Search::UsageQuery.new(name_id).results
    debug("ref_citations.class: #{ref_citations.class}")
    usage_instance_ids = ref_citations.map(&:instance_id)
    debug("usage_instance_ids.inspect: #{usage_instance_ids.inspect}")
    synonym_bunch = Name::Search::Synonym::BunchQuery.new(usage_instance_ids)
    @name_usages = ref_citations.collect do |ref_citation|
      append_misapp = false
      if ref_citation.misapplied == 't'
        debug("                                                                         --")
        debug("New ref citation")
        debug("misapplied!")
        debug("ref_citation.instance_id: #{ref_citation.instance_id}")
        debug("ref_citation.instance_type_name: #{ref_citation.instance_type_name}")
        debug("ref_citation.name_id: #{ref_citation.name_id}")
        debug("ref_citation.reference_id: #{ref_citation.reference_id}")
        debug("ref_citation.instance_page: #{ref_citation.instance_page}")
        same_name = prev_name_id == ref_citation.name_id
        same_ref = prev_ref_id == ref_citation.reference_id
        same_type = prev_type == ref_citation.instance_type_name
        same_page = prev_page == ref_citation.instance_page
        append_misapp = same_name & same_ref & same_type & same_page
        prev_name_id = ref_citation.name_id
        prev_ref_id = ref_citation.reference_id
        prev_type = ref_citation.instance_type_name
        prev_page = ref_citation.instance_page
      end

      merged_usage = nil
      if append_misapp
        debug("APPEND!!!")
        debug("We need: latest_usage.class: #{latest_usage}")
        # Assumes no synonyms
        latest_usage.append(ref_citation) unless ref_citation.nil? || latest_usage.nil?
        #latest_usage = OpenStruct.new
        merged = true
        merged_usage = Name::Search::Usage.new(ref_citation, synonym_bunch, merged) unless ref_citation.nil?
      else
        latest_usage = Name::Search::Usage.new(ref_citation, synonym_bunch) unless ref_citation.nil?
      end
      debug("latest_usage.class: #{latest_usage}")
      merged_usage.nil? ? latest_usage : merged_usage
    end
    @name_usages.reject! {|e| e.merged}
  end

  def debug(s)
    # Rails.logger.debug("Name::Search::Usages: #{s}")
  end
end

