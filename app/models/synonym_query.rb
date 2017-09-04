# frozen_string_literal: true

# For a given instance ID, retrieve a set of ordered
# synonymy instance results suitable for displaying within a name usage.
class SynonymQuery
  attr_reader :results, :id
  def initialize(instance_id)
    Rails.logger.debug("SynonymQuery start ==================================================")
    @instance_id = instance_id
    @results = []
    Rails.logger.debug("SynonymQuery endish ==================================================")
    query
  end

  def query
    Instance.where(cited_by_id: @instance_id)
            .joins(:instance_type)
            .where(instance_type: { misapplied: false})
            .joins(:name)
            .select(select_list)
            .each do |synonym|
        @results.push(Synonym.new(synonym))
    end
  end

  def select_list
    "instance.id, instance_type.name instance_type_name, instance.page, \
     instance.page_qualifier, instance_type.has_label instance_type_has_label, \
     instance_type.of_label instance_type_of_label, \
     name.full_name name_full_name"
  end
end
