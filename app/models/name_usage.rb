class NameUsage

  attr_reader :misapplied_by_id, :misapplied_by_citation, :misapplied_on_page

  def initialize(name_usage_query_record, synonym_bunch)
    Rails.logger.debug("")
    Rails.logger.debug("NameUsage start ===============================================")
    @name_usage = name_usage_query_record
    Rails.logger.debug("NameUsage a ===============================================")
    @synonym_bunch = synonym_bunch
    Rails.logger.debug("NameUsage b ===============================================")
    if @name_usage.misapplied
      Rails.logger.debug("NameUsage c ===============================================")
      instance = Instance.find(@name_usage.instance_id)
      Rails.logger.debug("NameUsage c1===============================================")
      Rails.logger.debug("@name_usage.instance_id: #{@name_usage.instance_id} ==================")
      inst1 = Instance.find(@name_usage.instance_id)
      Rails.logger.debug("inst1.cited_by_id: #{inst1.cited_by_id} ==================")
      if inst1.cited_by_id.blank?
        cited_by = nil
        @misapplied_to_id = -1
        @misapplied_to_name = nil
      else
        cited_by = Instance.find(Instance.find(@name_usage.instance_id).cited_by_id) unless inst1.cited_by_id.nil?
        Rails.logger.debug("NameUsage c2===============================================")
        @misapplied_to_id = cited_by.name_id
        Rails.logger.debug("NameUsage c3===============================================")
        @misapplied_to_name = cited_by.name.full_name
      end
      Rails.logger.debug("NameUsage c4===============================================")
      inst2 = Instance.find(instance.id)
      if inst2.cites_id.blank?
        cites = nil
        @misapplied_by_id = -1
        @misapplied_by_citation = nil
        @misapplied_on_page = nil
      else
        cites = Instance.find(Instance.find(instance.id).cites_id)
        Rails.logger.debug("NameUsage c5===============================================")
        @misapplied_by_id = cites.reference_id
        Rails.logger.debug("NameUsage c6===============================================")
        @misapplied_by_citation = cites.reference.citation
        Rails.logger.debug("NameUsage c7===============================================")
        @misapplied_on_page = cites.page
      end
      Rails.logger.debug("NameUsage c8===============================================")
    else
      Rails.logger.debug("NameUsage d ===============================================")
      @misapplied_to_id = -1
      @misapplied_to_name = ''
      @misapplied_by_id = ''
      @misapplied_on_page = ''
    end
    Rails.logger.debug("NameUsage e ===============================================")
    Rails.logger.debug("NameUsage end   ===============================================")
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
    @name_usage.instance_page #@instance.page
  end

  def page_qualifier
    @name_usage.instance_page_qualifier #@instance.page_qualifier
  end

  def year
    @name_usage.reference_year
  end

  def misapplied
    @name_usage.misapplied
  end

  def misapplied_to_name
    @misapplied_to_name
  end

  def misapplied_to_id
    @misapplied_to_id
  end

  def standalone
    'standalone' #@instance.standalone?
  end
  
  def synonyms
    Rails.logger.debug("NameUsage#synonyms start +++++++++++++++++++++++++++++++++++++++++++++")
    res = SynonymPick.new(@name_usage.instance_id, @synonym_bunch).results
    Rails.logger.debug("NameUsage#synonyms endish +++++++++++++++++++++++++++++++++++++++++++++")
    res
  end

  def notes
    Rails.logger.debug('notes')
    Rails.logger.debug('notes')
    Rails.logger.debug('notes')
    Rails.logger.debug('notes')
    Rails.logger.debug('notes')
    Rails.logger.debug('notes')
    Rails.logger.debug('notes')
    Rails.logger.debug(@name_usage.class)
    Rails.logger.debug(@name_usage.class)
    Rails.logger.debug(@name_usage.class)
    Rails.logger.debug(@name_usage.class)
    @notes = []
    #Rails.logger.debug(@name_usage.to_yaml)
    #@name_usage.instance_notes.each do |note|
      #@notes.push(note)
    #end
  end

  def template(nr)
    ActiveSupport::HashWithIndifferentAccess.new(
      sequence: nil,
      treat_as_new_reference: true,
      name_id: nr.name_id,
      full_name: nr.full_name,
      name_citation: nr.full_name_html,
      reference_id: nr.reference_id,
      author_id: nil,
      citation_html: nr.reference_citation_html,
      page: nil,
      type_notes: nil,
      instance_notes_count: 0,
      instance_notes: nil,
      common_names_count: 0,
      common_names: [],
      cited_by_count: 0,
      cited_by: [],
      accepted_name: nil,
      excluded_name: nil,
      declared_bt: nil,
      standalone_instances: [],
      relationship_instances: [],
      misapplications: [],
      protologue: nil,
      images: nil,
      has_names_within: true,
    )
  end
end
