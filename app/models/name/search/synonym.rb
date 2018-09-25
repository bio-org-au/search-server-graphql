# frozen_string_literal: true

# Attributes for synonym type.
class Name::Search::Synonym
  attr_reader :id, :full_name, :full_name_html, :instance_type, :page, :label,
              :page_qualifier, :name_status_name, :has_type_synonym,
              :of_type_synonym, :name_id, :reference_citation, :reference_page,
              :misapplied, :misapplication_citation_details, :year

  def initialize(instance, has_or_of_label = 'has', misapp_name_repeated = false)
    @id = instance[:instance_id]
    @instance_type = instance[:instance_type_name]
    if has_or_of_label == 'has'
      @label = instance[:instance_type_has_label]
      @full_name = instance[:name_full_name]
      @full_name_html = instance[:name_full_name_html]
      @name_id = instance[:name_id]
      unless instance[:name_status_name] == '[n/a]'
        @name_status_name = instance[:name_status_name]
      end
    else
      @label = instance[:instance_type_of_label]
      cited_by_name = Instance.find(Instance.find(@id).cited_by_id).name
      @full_name = cited_by_name.full_name
      @full_name_html = cited_by_name.full_name_html
      @name_id = cited_by_name.id
      unless cited_by_name.name_status_name == '[n/a]'
        @name_status_name = cited_by_name.name_status_name
      end
    end
    @page = instance[:page]
    @page_qualifier = instance[:page_qualifier]
    # Send the cited instance reference year
    # Used for quickly verifying order is correct
    # if instance[:cites_id].blank?
    #   @year = nil
    # else
    #   cited_instance = Instance.find(instance[:cites_id]) 
    #   @year = cited_instance.reference.year
    # end
    @has_type_synonym = has_or_of_label == 'has'
    @of_type_synonym = !@has_type_synonym
    @misapplied = instance[:misapplied] == true
    unless instance[:cites_id].blank?
      cited_instance = Instance.find(instance[:cites_id]) 
      if @misapplied
        mrec = OpenStruct.new
        mrec.misapplied_in_reference_citation = cited_instance.reference.citation_html
        mrec.misapplied_in_reference_citation_html = cited_instance.reference.citation_html
        mrec.misapplied_in_reference_id = cited_instance.reference.id
        mrec.misapplied_on_page = cited_instance.page
        mrec.misapplied_on_page_qualifier = cited_instance.page_qualifier
        mrec.misapplied_in_reference_year = cited_instance.reference.year
        mrec.same_name_as_preceding_misapplication = false
        mrec.name_is_repeated = misapp_name_repeated
        @misapplication_citation_details = mrec
      end
    end
  end
end
