# frozen_string_literal: true

# Provide data for a name usage type from a name usage query record.
# Allow for raw data to be passed on from the name usage query record,
# but also allow for wrapped or otherwise processed data.
class Name::Search::Usage
  attr_reader :misapplied_by_citation, :misapplied_on_page,
              :misapplied_to_name, :misapplied_to_id, :misapplication_label,
              :misapplied_by_reference_id, :merged

  def initialize(name_usage_query_record, synonym_bunch, merged = false)
    debug('start')
    @merged = merged
    @name_usage_query_record = name_usage_query_record
    @synonym_bunch = synonym_bunch
    @instance = Instance.find(@name_usage_query_record.instance_id)
    debug("@instance.id: #{@instance.id}; cites_id: #{@instance.cites_id}; cited_by_id: #{@instance.cited_by_id}; standalone: #{@instance.standalone?}")
    @instance_type_name = @name_usage_query_record.instance_type_name
    @primary_instance = @name_usage_query_record.primary_instance == 't'
  end

  def debug(s)
    Rails.logger.debug("==============================================")
    Rails.logger.debug("Name::Search::Usage: #{s}")
    Rails.logger.debug("==============================================")
  end

  def append(name_usage_query_record)
    debug("append method")
    instance = Instance.find(name_usage_query_record.instance_id)
    unless instance.cites_id.blank?
      cites = Instance.find(instance.cites_id)
      mir = OpenStruct.new
      mir.citation = cites.reference.citation
      mir.id = cites.reference_id
      mir.page = cites.page
      mir.page_qualifier = cites.page_qualifier
      mir.display_entry = 'display entry'
      misapplication_details.misapplied_in_references.push mir
    end
  end

  def reference_details
    debug('reference_details method')
    record = OpenStruct.new
    if @name_usage_query_record.cited_by_id.blank?
      record.id = @name_usage_query_record.reference_id
      record.citation = @name_usage_query_record.reference_citation
      record.citation_html = @name_usage_query_record.reference_citation_html
      record.page = @name_usage_query_record.instance_page
      record.year = @name_usage_query_record.reference_year
    else
      record.id = @name_usage_query_record.reference_id
      record.citation = @name_usage_query_record.reference_citation
      record.citation_html = @name_usage_query_record.reference_citation_html
      if @name_usage_query_record.instance_page.blank?
        citer = Instance.find(@name_usage_query_record.cited_by_id)
        record.page = "~ #{citer.page}" unless citer.page.blank?
      else
        record.page = @name_usage_query_record.instance_page
      end
      record.year = @name_usage_query_record.reference_year
    end
    record.bhl_url = @name_usage_query_record.bhl_url
    record
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

  def protologue_link
    return nil unless @instance.has_protologue?
    @instance.protologue_link
  end

  def name_id
    @name_usage_query_record.name_id
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

  def misapplication
    misapplication?
  end

  def misapplication?
    @name_usage_query_record.misapplied == 't'
  end

  def misapplication_details
    return nil unless misapplication?
    MisapplicationDetails.new(@name_usage_query_record).content
  end

  def xhas_label
    @name_usage_query_record.has_label
  end

  def xof_label
    @name_usage_query_record.of_label
  end

  def standalone
    @instance.standalone?
  end

  def synonyms
    Name::Search::Synonym::Pick.new(@instance.id, @synonym_bunch).results
  end

  def accepted_tree_details
    return nil unless tree_element_found_for_this_instance?
    AcceptedTree.new(@name_usage_query_record).details
  end

  def non_current_accepted_tree_details
    return nil if tree_element_found_for_this_instance?
    return nil unless non_current_tree_element_for_instance?
    NonCurrentAcceptedTree.new(@name_usage_query_record).details
  end

  def non_current_tree_element_for_instance?
    TreeElement.where(instance_id: @name_usage_query_record.instance_id)
               .joins(tree_version_elements: {tree_version: :tree})
               .where('tree.accepted_tree = true')
               .where('tree_version.id != tree.current_tree_version_id')
               .size > 0
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

  private

  def tree_element_found_for_this_instance?
    @name_usage_query_record.tree_element_id.to_i.positive? &&
      @name_usage_query_record.tree_element_instance_id == @instance.id
  end
end
