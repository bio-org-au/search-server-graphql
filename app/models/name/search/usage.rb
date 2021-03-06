# frozen_string_literal: true

# Provide data for a name usage type from a name usage query record.
# Allow for raw data to be passed on from the name usage query record,
# but also allow for wrapped or otherwise processed data.
class Name::Search::Usage
  attr_reader :misapplied_by_citation, :misapplied_on_page,
              :misapplied_to_name, :misapplied_to_id, :misapplication_label,
              :misapplied_by_reference_id, :merged

  def initialize(name_usage_query_record, synonym_bunch, merged = false, tree_info)
    @merged = merged
    @name_usage_query_record = name_usage_query_record
    @synonym_bunch = synonym_bunch
    @instance_id = @name_usage_query_record.instance_id
    @instance_type_name = @name_usage_query_record.instance_type_name
    @tree_info = tree_info
  end

  def debug(msg)
    tag = 'Name::Search::Usage'
    Rails.logger.debug("#{tag} for instance: #{@instance_id}: #{msg}")
  end

  def append(name_usage_query_record)
    instance = Instance.find(name_usage_query_record.instance_id)
    unless instance.cites_id.blank?
      cites = Instance.find(instance.cites_id)
      mir = OpenStruct.new
      mir.citation = cites.reference.citation
      mir.id = cites.reference_id
      mir.page = cites.page
      mir.page_qualifier = cites.page_qualifier
      mir.display_entry = 'display entry'
      misapplication_details&.misapplied_in_references&.push mir
    end
  end

  def reference_details
    record = OpenStruct.new
    if @name_usage_query_record.cited_by_id.blank?
      record.id = @name_usage_query_record.reference_id
      record.citation = @name_usage_query_record.reference_citation
      record.citation_html = @name_usage_query_record.reference_citation_html
      record.page = if @name_usage_query_record.instance_page.blank?
                      '-'
                    else
                      @name_usage_query_record.instance_page.gsub(/<NR>/, '–')
                    end
    else
      record.id = @name_usage_query_record.reference_id
      record.citation = @name_usage_query_record.reference_citation
      record.citation_html = @name_usage_query_record.reference_citation_html
      if @name_usage_query_record.instance_page.blank?
        citer = Instance.find(@name_usage_query_record.cited_by_id)
        record.page = "~ #{citer.page.gsub(/<NR>/, '–')}" unless citer.page.blank?
      else
        record.page = @name_usage_query_record.instance_page.gsub(/<NR>/, '–')
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
    @name_usage_query_record.primary_instance == true ||
      @name_usage_query_record.primary_instance == 't'
  end

  # When I checked there were no protologue line resources.
  def protologue_link
    return nil unless @name_usage_query_record.protologue_count > 0

    @instance ||= Instance.find(@name_usage_query_record.instance_id)
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
    if @name_usage_query_record.instance_page.blank?
      @name_usage_query_record.instance_page
    else
      @name_usage_query_record.instance_page.gsub(/<NR>/, '–')
    end
  end

  def page_qualifier
    @name_usage_query_record.instance_page_qualifier
  end

  def year
    @name_usage_query_record.reference_year
  end

  def misapplied
    @name_usage_query_record.misapplied == true
  end

  def misapplication
    misapplication?
  end

  def misapplication?
    @name_usage_query_record.misapplied == true ||
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
    @name_usage_query_record.standalone?
  end

  def synonyms
    Name::Search::Synonym::Pick.new(@name_usage_query_record.instance_id, @synonym_bunch).results
  end

  def accepted_tree_details
    AcceptedTree.new(@tree_info).details
  end

  def non_current_accepted_tree_details
    return nil unless non_current_tree_element_for_instance?

    NonCurrentAcceptedTree.new(@name_usage_query_record).details
  end

  def non_current_tree_element_for_instance?
    !TreeElement.where(instance_id: @name_usage_query_record.instance_id)
                .joins(tree_version_elements: { tree_version: :tree })
                .where('tree.accepted_tree = true')
                .where('tree_version.id != tree.current_tree_version_id').empty?
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
