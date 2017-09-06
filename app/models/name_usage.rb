# frozen_string_literal: true

# Provide data for a name usage type from a name usage query record.
# Allow for raw data to be passed on from the name usage query record,
# but also allow for wrapped or otherwise processed data.
class NameUsage
  attr_reader :misapplied_by_id, :misapplied_by_citation, :misapplied_on_page,
              :misapplied_to_name, :misapplied_to_id

  def initialize(name_usage_query_record, synonym_bunch)
    @name_usage = name_usage_query_record
    @synonym_bunch = synonym_bunch
    initialize_misapplied
  end

  def initialize_misapplied
    @misapplied_to_id = nil
    @misapplied_to_name = ''
    @misapplied_by_id = nil
    @misapplied_on_page = ''
    return unless @name_usage.misapplied == 't'
    prepare_misapplied
  end

  def prepare_misapplied
    cited_by_for_misapplied
    cites_for_misapplied
  end

  def cited_by_for_misapplied
    inst1 = Instance.find(@name_usage.instance_id)
    return if inst1.cited_by_id.blank?
    cited_by = Instance.find(Instance.find(@name_usage.instance_id).cited_by_id)
    @misapplied_to_id = cited_by.name_id
    @misapplied_to_name = cited_by.name.full_name
  end

  def cites_for_misapplied
    instance = Instance.find(@name_usage.instance_id)
    inst2 = Instance.find(instance.id)
    return if inst2.cites_id.blank?
    cites = Instance.find(Instance.find(instance.id).cites_id)
    @misapplied_by_id = cites.reference_id
    @misapplied_by_citation = cites.reference.citation
    @misapplied_on_page = cites.page
  end

  def instance_id
    @name_usage.instance_id
  end

  def instance_type_name
    @name_usage.instance_type_name
  end

  def primary_instance
    @name_usage.primary_instance
  end

  def name_id
    @name_usage.name_id
  end

  def reference_id
    @name_usage.reference_id
  end

  def citation
    @name_usage.reference_citation
  end

  def page
    @name_usage.instance_page
  end

  def page_qualifier
    @name_usage.instance_page_qualifier
  end

  def year
    @name_usage.reference_year
  end

  def misapplied
    @name_usage.misapplied == 't'
  end

  def standalone
    'standalone'
  end

  def synonyms
    res = SynonymPick.new(@name_usage.instance_id, @synonym_bunch).results
    res
  end

  def notes
    notes = []
    InstanceNote.where(instance_id: @name_usage.instance_id).each do |note|
      notes.push(note)
    end
    notes
  end
end
