# frozen_string_literal: true

# Provide data for a name usage type from a name usage query record.
# Allow for raw data to be passed on from the name usage query record,
# but also allow for wrapped or otherwise processed data.
class Name::Search::Usage
  attr_reader :misapplied_by_id, :misapplied_by_citation, :misapplied_on_page,
              :misapplied_to_name, :misapplied_to_id, :misapplication_label,
              :misapplied_by_reference_id

  def initialize(name_usage_query_record, synonym_bunch)
    @name_usage_query_record = name_usage_query_record
    @synonym_bunch = synonym_bunch
    initialize_misapplied
  end

  def initialize_misapplied
    @misapplied_to_id = nil
    @misapplied_to_name = ''
    @misapplied_by_id = nil
    @misapplied_on_page = ''
    @misapplication_label = ''
    return unless @name_usage_query_record.misapplied == 't'
    prepare_misapplied
  end

  def prepare_misapplied
    cited_by_for_misapplied
    cites_for_misapplied
  end

  def cited_by_for_misapplied
    inst1 = Instance.find(@name_usage_query_record.instance_id)
    return if inst1.cited_by_id.blank?
    cited_by = Instance.find(Instance.find(@name_usage_query_record.instance_id).cited_by_id)
    @misapplied_to_id = cited_by.name_id
    @misapplied_to_name = cited_by.name.full_name
    @misapplication_label = @name_usage_query_record.of_label
  end

  def cites_for_misapplied
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

  def accepted_tree_status
    @name_usage_query_record[:accepted_tree_status]
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

  def has_label
    @name_usage_query_record.has_label
  end

  def of_label
    @name_usage_query_record.of_label
  end

  def standalone
    'standalone'
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
