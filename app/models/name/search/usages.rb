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

    usage_query_results = Name::Search::UsageQuery.new(name_id).results

    debug("usage query gives us a usage_query_results.class: #{usage_query_results.class}")

    usage_instance_ids = usage_query_results.map(&:instance_id)
    usage_cited_by_ids = usage_query_results.map(&:cited_by_id).reject(&:blank?)
    instance_ids = usage_instance_ids | usage_cited_by_ids
    debug("extract the instance ids -> instance_ids.inspect: #{instance_ids.inspect}")
    debug('query all the synonyms for all of those instances')
    synonym_bunch = Name::Search::Synonym::BunchQuery.new(instance_ids)


    debug('loop through the ref citations (instances for the name)')
    @name_usages = usage_query_results.collect do |ref_citation|
      debug('top of loop')
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
        debug('Not a misapp, so get the latest usage')
        latest_usage = Name::Search::Usage.new(ref_citation, synonym_bunch) unless ref_citation.nil?
      end
      debug("latest_usage.class: #{latest_usage}")
      debug('bottom of loop')
      merged_usage.nil? ? latest_usage : merged_usage
    end
    @name_usages.reject! {|e| e.merged}
  end

  def debug(s)
    Rails.logger.debug("==============================================")
    Rails.logger.debug("Name::Search::Usages: #{s}")
    Rails.logger.debug("==============================================")
  end
end

