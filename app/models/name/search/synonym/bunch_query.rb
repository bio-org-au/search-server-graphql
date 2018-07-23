# frozen_string_literal: true

# For a given set of instance IDs, retrieve a set of ordered
# synonymy instance results suitable for displaying within a bunch of
# name usages.
#
# This is a query optimisation - 1 query per set of instances instead of 1
# query per instance
class Name::Search::Synonym::BunchQuery
  attr_reader :query, :array_of_ids, :results
  def initialize(array_of_instance_ids)
    debug('start')
    @array_of_ids = array_of_instance_ids
    @results = []
    @query = run_query unless @array_of_ids.blank?
  end

  def ids
    array_of_ids.join(',').to_s
  end

  # Ordering is important because this ordering of the whole set is retained
  # for each subset allocated to a reference usage.  And we want the 
  # synonymns for any single ref. usage to appear in this order:
  # 1. non-misapps first, followed by misapps
  # 2. name-sort order within
  # 3. year of the reference withing name-sort order
  def bunch_query
    debug('bunch_query')
    Instance.where("cited_by_id in (#{ids}) or cites_id in (#{ids})")
            .joins(:instance_type)
            .joins(name: :name_status)
            .joins(:reference)
            .select(select_list)
      .order('instance_type.misapplied, name.sort_name, reference.year')
  end

  def run_query
    bunch_query.each do |r|
      @results.push(r)
    end
  end

  def select_list
    "instance.id instance_id, instance_type.name instance_type_name, \
    instance.page, instance.page_qualifier, instance_type.has_label \
    instance_type_has_label, instance_type.of_label instance_type_of_label, \
    name.full_name name_full_name, name.full_name_html name_full_name_html, \
    instance.cited_by_id, instance.cites_id, name_status.name name_status_name,\
    name_id, instance_type.misapplied, reference.year, \
    reference.id reference_id, reference.citation reference_citation"
  end

  def debug(s)
    Rails.logger.debug("==============================================")
    Rails.logger.debug("Name::Search::Synonym::BunchQuery: #{s}")
    Rails.logger.debug("==============================================")
  end
end
