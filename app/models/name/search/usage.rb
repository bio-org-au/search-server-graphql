# frozen_string_literal: true

# Provide data for a name usage type from a name usage query record.
# Allow for raw data to be passed on from the name usage query record,
# but also allow for wrapped or otherwise processed data.
class Name::Search::Usage
  attr_reader :misapplied_by_id, :misapplied_by_citation, :misapplied_on_page,
              :misapplied_to_name, :misapplied_to_id, :misapplication_label,
              :misapplied_by_reference_id, :misapplication_details,
              :instance_type_name, :instance_id, :primary_instance,
              :accepted_tree_status

  def initialize(name_usage_query_record, synonym_bunch)
    debug("name_usage_query_record.instance_id: #{name_usage_query_record.instance_id}") 
    @name_usage_query_record = name_usage_query_record
    @synonym_bunch = synonym_bunch
    @instance = Instance.find(@name_usage_query_record.instance_id)
    @instance_id = @instance.id
    debug("@instance.id: #{@instance.id}; 
                       cites_id: #{@instance.cites_id}; \
                       cited_by_id: #{@instance.cited_by_id}; \
                       standalone: #{@instance.standalone?}") 
    @instance_type_name = @name_usage_query_record.instance_type_name
    @primary_instance = @name_usage_query_record.primary_instance == 't'
    @accepted_tree_status = @name_usage_query_record[:accepted_tree_status]
    initialize_misapplied
  end

  def debug(s)
    Rails.logger.debug("Name::Search::Usage: #{s}")
  end

  def reference_details
    record = OpenStruct.new
    record.id = @name_usage_query_record.reference_id
    record.citation = @name_usage_query_record.reference_citation
    record.citation_html = @name_usage_query_record.reference_citation_html
    record.page = @name_usage_query_record.instance_page
    record.year = @name_usage_query_record.reference_year
    record
  end

  def xinitialize_misapplied
    @misapplied_to_id = nil
    @misapplied_to_name = ''
    @misapplied_by_id = nil
    @misapplied_on_page = ''
    @misapplication_label = ''
    return unless @name_usage_query_record.misapplied == 't'
    prepare_misapplied
  end

  def initialize_misapplied
    @misapplication_details = []
    return if @instance.standalone?
    return unless misapplication?
    prepare_misapplied
  end

  def usage_is_a_misapplication?
    @name_usage_query_record.misapplied == 't'
  end

  def xprepare_misapplied
    cited_by_for_misapplied
    cites_for_misapplied
  end

  def prepare_misapplied
    return if @instance.standalone?
    return if @instance.cites_id.blank?
    @cited_by = Instance.find(@instance.cited_by_id)
    @cites = Instance.find(@instance.cites_id)
    if @instance.reference_id == @cited_by.reference_id
      cites_and_cited_by_for_misapplied_in_forward_direction
    else
      cites_and_cited_by_for_misapplied_in_backward_direction
    end
    xcited_by_for_misapplied
    xcites_for_misapplied
  end

  def this_cites_a_misapplication
    
  end

  def this_is_cited_as_a_misapplication


  end

  def cites_and_cited_by_for_misapplied_in_forward_direction
    return if @instance.cited_by_id.blank?
    cited_by = Instance.find(@instance.cited_by_id)
    rec = OpenStruct.new
    rec.direction = 'forward'
    rec.misapplied_to_name_id = cited_by.name_id
    rec.misapplied_to_full_name = cited_by.name.full_name
    rec.misapplication_type_label = @name_usage_query_record.of_label

    unless @instance.cites_id.blank?
      cites = Instance.find(@instance.cites_id)
      rec.misapplied_in_reference_citation = cites.reference.citation
      rec.misapplied_in_reference_id = cites.reference_id
      rec.misapplied_on_page = cites.page
      rec.misapplied_on_page_qualifier = cites.page_qualifier
    else
      ref.misapplied_in_reference_citation = nil
      ref.misapplied_in_reference_id = nil
      rec.misapplied_on_page = nil
      rec.misapplied_on_page_qualifier = nil
    end
    @misapplication_details.push(rec)
  end

  def cites_and_cited_by_for_misapplied_in_backward_direction
    throw 'backwards'
    return if @instance.cited_by_id.blank?
    cited_by = Instance.find(@instance.cited_by_id)
    rec = OpenStruct.new
    rec.direction = 'backward'
    rec.name_id = cited_by.name_id
    rec.misapplied_to_full_name = cited_by.name.full_name
    rec.misapplication_type_label = @name_usage_query_record.of_label

    unless @instance.cites_id.blank?
      cites = Instance.find(@instance.cites_id)
      rec.misapplied_in_reference_citation = cites.reference.citation
      rec.misapplied_in_reference_id = cites.reference_id
      rec.misapplied_on_page = cited_by.page
      rec.misapplied_on_page_qualifier = cites.page_qualifier
    else
      ref.misapplied_in_reference_citation = nil
      ref.misapplied_in_reference_id = nil
      rec.misapplied_on_page = nil
      rec.misapplied_on_page_qualifier = nil
    end
    @misapplication_details.push(rec)
  end

  def xcited_by_for_misapplied
    inst1 = Instance.find(@name_usage_query_record.instance_id)
    return if inst1.cited_by_id.blank?
    cited_by = Instance.find(Instance.find(@name_usage_query_record.instance_id).cited_by_id)
    @misapplied_to_id = cited_by.name_id
    @misapplied_to_name = cited_by.name.full_name
    @misapplication_label = @name_usage_query_record.of_label
  end

  def cites_for_misapplied
    return if @instance.cites_id.blank?
    cites = Instance.find(@instance.cites_id)
    rec = OpenStruct.new
    rec.name_id = -1 
    rec.full_name = cites.name.full_name
    rec.type_label = @name_usage_query_record.of_label
    rec.reference_id = cites.reference_id
    rec.reference_citation = cites.reference.citation
    rec.reference_id = cites.reference.id
    rec.page = cites.page
    rec.page_qualifier = cites.page_qualifier
    @misapplication_details.push(rec)
  end

  def xcites_for_misapplied
    instance = Instance.find(@name_usage_query_record.instance_id)
    inst2 = Instance.find(instance.id)
    return if inst2.cites_id.blank?
    cites = Instance.find(Instance.find(instance.id).cites_id)
    @misapplied_by_id = cites.reference_id
    @misapplied_by_citation = cites.reference.citation
    @misapplied_by_reference_id = cites.reference.id
    @misapplied_on_page = cites.page
  end

  def instance_id
    @name_usage_query_record.instance_id
  end

  def instance_type_name
    @name_usage_query_record.instance_type_name
  end

  def primary_instance
    @name_usage_query_record.primary_instance == 't'
  end

  def name_id
    @name_usage_query_record.name_id
  end

  def reference_id
    @name_usage_query_record.reference_id
  end

  def reference_id
    @name_usage_query_record.reference_id
  end

  def citation
    @name_usage_query_record.reference_citation
  end

  def page
    @name_usage_query_record.instance_page
  end

  def page_qualifier
    @name_usage_query_record.instance_page_qualifier
  end

  def year
    @name_usage_query_record.reference_year
  end

  def misapplied
    @name_usage_query_record.misapplied == 't'
  end

  def misapplication?
    @name_usage_query_record.misapplied == 't'
  end

  def has_label
    @name_usage_query_record.has_label
  end

  def of_label
    @name_usage_query_record.of_label
  end

  def standalone
    @instance.standalone?
  end

  def synonyms
    Name::Search::Synonym::Pick.new(@name_usage_query_record.instance_id, @synonym_bunch).results
  end
 
  def notes
    notes = []
    InstanceNote.where(instance_id: @name_usage_query_record.instance_id)
                .without_epbc_notes
                .ordered_for_display
                .each do |note|
      notes.push(note)
    end
    notes
  end
end
