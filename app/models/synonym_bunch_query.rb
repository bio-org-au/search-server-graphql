# frozen_string_literal: true

# For a given set of instance IDs, retrieve a set of ordered
# synonymy instance results suitable for displaying within a bunch of
# name usages.
class SynonymBunchQuery
  attr_reader :query, :array_of_ids, :results
  def initialize(array_of_instance_ids)
    @array_of_ids = array_of_instance_ids
    @results = []
    @query = define_query unless @array_of_ids.blank?
  end

  def define_query
    Instance.where("cited_by_id in (#{@array_of_ids.join(',')}) or cites_id in (#{@array_of_ids.join(',')})")
            .joins(:instance_type)
            .where(instance_type: { misapplied: false })
            .joins(:name)
            .select(select_list)
            .each do |record|
              hwia = ActiveSupport::HashWithIndifferentAccess.new
              hwia[:instance_id] = record.id
              hwia[:cited_by_id] = record.cited_by_id
              hwia[:instance_type_name] = record.instance_type_name
              hwia[:page] = record.page
              hwia[:page_qualifier] = record.page_qualifier
              hwia[:instance_type_has_label] = record.instance_type_has_label
              hwia[:instance_type_of_label] = record.instance_type_of_label
              hwia[:name_full_name] = record.name_full_name
              @results.push(hwia)
            end
  end

  def select_list
    "instance.id, instance_type.name instance_type_name, instance.page, \
     instance.page_qualifier, instance_type.has_label instance_type_has_label, \
     instance_type.of_label instance_type_of_label, \
     name.full_name name_full_name, instance.cited_by_id"
  end
end
