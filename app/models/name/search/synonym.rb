# frozen_string_literal: true

# Attributes for synonym type.
class Name::Search::Synonym
  attr_reader :id, :full_name, :instance_type, :page, :label,
              :page_qualifier, :name_status_name, :has_type_synonym,
              :of_type_synonym

  def initialize(instance, has_or_of_label = 'has')
    @id = instance[:instance_id]
    @instance_type = instance[:instance_type_name]
    if has_or_of_label == 'has'
      @label = instance[:instance_type_has_label]
      @full_name = instance[:name_full_name]
    else
      @label = instance[:instance_type_of_label]
      @full_name = Instance.find(Instance.find(@id).cited_by_id).name.full_name
    end
    @page = instance[:page]
    @page_qualifier = instance[:page_qualifier]
    @name_status_name = instance[:name_status_name]
    @has_type_synonym = has_or_of_label == 'has'
    @of_type_synonym = !@has_type_synonym
  end
end
