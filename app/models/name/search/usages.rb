# frozen_string_literal: true

# Retrieve and prepare name usages
class Name::Search::Usages
  attr_reader :name_usages

  def initialize(name_id)
    @name_id = name_id
    build
  end

  def build
    debug("For name: #{@name_id}")
    prev_name_id = prev_ref_id = -1
    prev_type = prev_page = 'not-one'
    latest_usage = nil
    @name = Name.find(@name_id)

    usage_query_results = Name::Search::UsageQuery.new(@name_id).results

    accepted_name = @name.accepted?
    excluded_name = @name.excluded?

    accepted_instance = (@name.accepted_instance if accepted_name)
    excluded_instance = (@name.excluded_instance if excluded_name)
    debug("accepted_instance: #{accepted_instance.try('id')}")
    debug("excluded_instance: #{excluded_instance.try('id')}")

    debug("usage query gives us a usage_query_results.class: #{usage_query_results.class}")

    usage_instance_ids = usage_query_results.map(&:instance_id)
    usage_cited_by_ids = usage_query_results.map(&:cited_by_id).reject(&:blank?)
    instance_ids = usage_instance_ids | usage_cited_by_ids
    debug("extract the instance ids -> instance_ids.inspect: #{instance_ids.inspect}")
    debug('query all the synonyms for all of those instances')
    synonym_bunch = Name::Search::Synonym::BunchQuery.new(instance_ids)

    debug('loop through the ref citations (instances for the name)')
    @name_usages = usage_query_results.collect do |ref_citation|
      debug("top of loop ===========                                              ref_citation.instance_id: #{ref_citation.instance_id}")

      debug('                                                                             --')
      if accepted_name && accepted_instance.id == ref_citation.instance_id

        # find the current accepted tree
        # ctv = Tree.accepted.first.current_tree_version

        tree_info = { accepted: true,
                      excluded: false,
                      tree_element_id: @name.accepted_tree_element.id,
                      tree_element_instance_id: @name.accepted_tree_element.instance_id,
                      tree_element_profile: @name.accepted_tree_element.profile,
                      tree_element_config: Tree.accepted.first.config }
      elsif excluded_name && excluded_instance.try('id') == ref_citation.instance_id
        debug("Name ##{@name.id} is excluded and this is the instance: #{excluded_instance.try('id')}")
        tree_info = { accepted: false,
                      excluded: true,
                      tree_element_id: @name.excluded_tree_element.id,
                      tree_element_instance_id: nil,
                      tree_element_profile: nil,
                      tree_element_config: nil }
      else
        tree_info = { accepted: false,
                      excluded: false }
      end
      debug('tree info')
      debug(tree_info.inspect)
      debug('end tree info')

      append_misapp = false
      debug("ref_citation.misapplied: #{ref_citation.misapplied}")
      # review_flag(ref_citation.misapplied)
      if ref_citation.misapplied == true || ref_citation.misapplied == 't'
        debug('                        [Misapplied!]                                                 --')
        debug('New ref citation')
        debug('misapplied!')
        debug("ref_citation.instance_type_name: #{ref_citation.instance_type_name}")
        debug("ref_citation.name_id: #{ref_citation.name_id}")
        debug("ref_citation.reference_id: #{ref_citation.reference_id}")
        debug("ref_citation.instance_page: #{ref_citation.instance_page}")
        same_name = prev_name_id == ref_citation.name_id
        same_ref = prev_ref_id == ref_citation.reference_id
        same_type = prev_type == ref_citation.instance_type_name
        same_page = prev_page == ref_citation.instance_page
        # merging is off because not working properly
        # append_misapp = same_name & same_ref & same_type & same_page
        prev_name_id = ref_citation.name_id
        prev_ref_id = ref_citation.reference_id
        prev_type = ref_citation.instance_type_name
        prev_page = ref_citation.instance_page
      end

      merged_usage = nil
      if append_misapp
        debug('APPEND!!!')
        debug("We need: latest_usage.class: #{latest_usage}")
        # Assumes no synonyms
        latest_usage.append(ref_citation) unless ref_citation.nil? || latest_usage.nil?
        # latest_usage = OpenStruct.new
        merged = true
        merged_usage = Name::Search::Usage.new(ref_citation, synonym_bunch, merged, tree_info) unless ref_citation.nil?
      else
        debug('Not a misapp, so get the latest usage')
        latest_usage = Name::Search::Usage.new(ref_citation, synonym_bunch, false, tree_info) unless ref_citation.nil?
      end
      debug("latest_usage.class: #{latest_usage}")
      debug('bottom of loop')
      merged_usage.nil? ? latest_usage : merged_usage
    end
    @name_usages.reject!(&:merged)
  end

  def review_flag(misapplied)
    if misapplied == true
      debug('misapplied == true')
    else
      debug('misapplied != true')
    end
    if misapplied == 't'
      debug("misapplied == 't'")
    else
      debug("misapplied != 't'")
    end
    if misapplied == 't' || misapplied == true
      debug("misapplied == 't' || misapplied == true")
    else
      debug("misapplied != 't' && misapplied != true")
    end
  end

  private

  def debug(msg)
    Rails.logger.debug("Name::Search::Usages: #{msg}")
  end
end
