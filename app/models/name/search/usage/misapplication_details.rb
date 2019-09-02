# frozen_string_literal: true

# Provide data for a name usage type from a name usage query record.
# Allow for raw data to be passed on from the name usage query record,
# but also allow for wrapped or otherwise processed data.
class Name::Search::Usage::MisapplicationDetails
  attr_reader :misapplied_by_citation, :misapplied_on_page,
              :misapplied_to_name, :misapplied_to_id, :misapplication_label,
              :misapplied_by_reference_id, :merged

  def initialize(name_usage_query_record)
    @name_usage_query_record = name_usage_query_record
    @instance = Instance.find(@name_usage_query_record.instance_id)
  end

  def debug(s)
    Rails.logger.debug("Name::Search::Usage::MisapplicationDetails: #{s}")
  end

  # Assumes misapplication relationship instance.
  def content
    prepare_misapplied
    @misapplication_details
  end

  def prepare_misapplied
    @misapplication_details = nil
    return if @instance.standalone? || @instance.cites_id.blank?

    @cited_by = Instance.find(@instance.cited_by_id)
    @cites = Instance.find(@instance.cites_id)
    if @instance.reference_id == @cited_by.reference_id
      cites_and_cited_by_for_misapplied_in_forward_direction
    else
      cites_and_cited_by_for_misapplied_in_backward_direction
    end
    cited_by_for_misapplied
  end

  def cited_by_for_misapplied
    return if @instance.cited_by_id.blank?

    @misapplied_to_id = @cited_by.name_id
    @misapplied_to_name = @cited_by.name.full_name
    @misapplication_label = @name_usage_query_record.of_label
  end

  def cites_and_cited_by_for_misapplied_in_forward_direction
    return if @instance.cited_by_id.blank?

    rec = build_forward_struct
    @misapplication_details = rec
  end

  def build_forward_struct
    rec = OpenStruct.new
    rec.direction = 'forward'
    rec.misapplied_to_name_id = @cited_by.name_id
    rec.misapplied_to_full_name = @cited_by.name.full_name
    rec.misapplication_type_label = @name_usage_query_record.of_label
    rec.misapplied_in_reference_citation = @cites.reference.citation
    rec.misapplied_in_reference_id = @cites.reference_id
    rec.misapplied_on_page = @cites.page
    rec.misapplied_on_page_qualifier = @cites.page_qualifier
    rec.misapplied_in_references = [build_misapp_in_ref]
    rec
  end

  def build_misapp_in_ref
    mir = OpenStruct.new
    mir.citation = @cites.reference.citation
    mir.id = @cites.reference_id
    mir.page = @cites.page
    mir.page_qualifier = @cites.page_qualifier
    mir.display_entry = 'display entry'
    mir
  end

  def cites_and_cited_by_for_misapplied_in_backward_direction
    throw 'backwards'
    return if @instance.cited_by_id.blank?

    rec = OpenStruct.new
    rec.direction = 'backward'
    rec.name_id = @cited_by.name_id
    rec.misapplied_to_full_name = @cited_by.name.full_name
    rec.misapplication_type_label = @name_usage_query_record.of_label
    if @instance.cites_id.blank?
      ref.misapplied_in_reference_citation = nil
      ref.misapplied_in_reference_id = nil
      rec.misapplied_on_page = nil
      rec.misapplied_on_page_qualifier = nil
    else
      rec.misapplied_in_reference_citation = @cites.reference.citation
      rec.misapplied_in_reference_id = @cites.reference_id
      rec.misapplied_on_page = cited_by.page
      rec.misapplied_on_page_qualifier = @cites.page_qualifier
    end
    @misapplication_details = rec
  end
end
