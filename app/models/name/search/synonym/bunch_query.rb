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
    @array_of_ids = array_of_instance_ids
    @results = []
    @query = run_query unless @array_of_ids.blank?
  end

  def ids
    array_of_ids.join(',').to_s
  end

  def bunch_query
    Instance.where("cited_by_id in (#{ids}) or cites_id in (#{ids})")
            .joins(:instance_type)
            .where(instance_type: { misapplied: false })
            .joins(name: :name_status)
            .select(select_list)
            .order('instance_type.sort_order')
  end

  def run_query
    bunch_query.each do |record|
      @results.push(record)
    end
  end

  def select_list
    "instance.id instance_id, instance_type.name instance_type_name, \
    instance.page, instance.page_qualifier, instance_type.has_label \
    instance_type_has_label, instance_type.of_label instance_type_of_label, \
    name.full_name name_full_name, name.full_name_html name_full_name_html,
    instance.cited_by_id, name_status.name name_status_name, name_id"
  end
end
