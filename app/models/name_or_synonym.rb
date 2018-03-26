# frozen_string_literal: true

# Rails model
class NameOrSynonym < ActiveRecord::Base
  self.table_name = "name_or_synonym_vw"
  ACCEPTED_TREE_ACCEPTED = "ApcConcept"
  ACCEPTED_TREE_EXCLUDED = "ApcExcluded"
  ACCEPTED_NAME = 'accepted-name'
  EXCLUDED_NAME = 'excluded-name'
  CROSS_REFERENCE = 'cross-reference'

  scope :default_ordered, (lambda do
    order("sort_name,
          case cites_misapplied when true then 'Z'
          else 'A' end, cites_cites_ref_year, accepted_full_name, reference_id")
  end)

  def order_string
    "#{sort_name}#{case cites_misapplied when 't' then 'Z' else 'A' end}#{cites_cites_ref_year}#{accepted_full_name}#{reference_id}"
  end
  # "Union with Active Record"
  # http://thepugautomatic.com/2014/08/union-with-active-record/
  #
  # Gets past this error:
  #   ERROR:  bind message supplies 0 parameters, but
  #   prepared statement "" requires 2
  #
  # See the explanation here: https://github.com/rails/rails/issues/13686
  def self.name_matches(search_term = "x", accepted = {accepted: true, excluded: true})
    if accepted[:accepted] and accepted[:excluded]
      query1 = AcceptedName.name_matches(search_term)
    elsif accepted[:accepted]
      query1 = AcceptedName.name_matches(search_term).accepted
    elsif accepted[:excluded]
      query1 = AcceptedName.name_matches(search_term).excluded
    end

    # query2 = AcceptedSynonym.name_matches(search_term)
    query2 = CrossReferenceSynonym.name_matches(search_term)
    sql = NameOrSynonym.connection.unprepared_statement do
      "((#{query1.to_sql}) UNION (#{query2.to_sql})) AS name_or_synonym_vw"
    end
    NameOrSynonym.from(sql)
  end

  def accepted_accepted?
    type_code == ACCEPTED_TREE_ACCEPTED
  end

  def accepted_excluded?
    type_code == ACCEPTED_TREE_EXCLUDED
  end

  def to_csv
    attributes.values_at(*Name.columns.map(&:name))
    [full_name, status.name].to_csv
  end

  def name_status_name
    NameStatus.find(name_status_id).name
  end

  def record_type
    if accepted_accepted?
      'accepted-name'
    elsif accepted_excluded?
      'excluded-name'
    else
      'cross-reference'
    end
  end

  def reference_citation
    return nil if reference_id == 0
    return nil if cross_reference?
    Reference.find(reference_id).citation
  end

  def accepted_taxon_comment
    return nil if cross_reference?
    #note_key_name_for_shard = "#{ShardConfig.tree_label} Comment"
    Rails.logger.info('point 1')
    note_key_name_for_shard = 'APC Comment'
    Rails.logger.info('point 2')
    note_keys = InstanceNoteKey.where(name: note_key_name_for_shard)
    Rails.logger.info('point 3')
    return nil if note_keys.blank?
    Rails.logger.info('point 4')
    InstanceNote.where(instance_id: instance_id).where(instance_note_key_id: note_keys.try('first').try('id')).try('first').try('value')
  end

  def accepted_taxon_distribution
    return nil unless accepted_name?
    note_key_name_for_shard = "#{ShardConfig.tree_label} Dist."
    note_keys = InstanceNoteKey.where(name: note_key_name_for_shard)
    return nil if note_keys.blank?
    InstanceNote.where(instance_id: instance_id).where(instance_note_key_id: note_keys.try('first').try('id')).try('first').try('value')
  end

  def cross_referenced_full_name
    accepted_full_name
  end

  def cross_referenced_full_name_id
    accepted_id
  end

  def synonyms
    unless cross_reference?
      Taxonomy::Search::Synonyms.new(instance_id)
    else
      []
    end
  end

  def accepted_name?
    record_type == 'accepted-name'
  end

  def cross_reference?
    record_type == 'cross-reference'
  end

  def cross_reference_misapplication_details
    if cross_reference? && misapplication? && cites_instance_id > 0
      citing_instance = Instance.find(cites_instance_id)

      details = OpenStruct.new
      details.citing_instance_id = citing_instance.id
      details.citing_reference_id = citing_instance.reference_id
      details.citing_reference_author_string_and_year = Instance.find(cites_instance_id).reference.author_string_and_year

      details.misapplying_author_string_and_year = "nos#{reference_citation}nos" #cites_cites_ref_year
       #taxon.reference_citation.sub(/\),.*/,')') unless taxon.reference_citation.nil?
      details.misapplying_author_string_and_year = citing_instance.this_cites.reference.author_string_and_year

      details.name_author_string = Instance.find(cites_instance_id).name.author_component_of_full_name.strip
      details.cites_simple_name = 'cites_simple_name' #'synonym.this_is_cited_by.name.simple_name'
      details.cites_page = 'cites_page' #'synonym.this_cites.page'
      details.pro_parte = citing_instance.instance_type.pro_parte
      details.is_doubtful = citing_instance.instance_type.doubtful?
    else
      details = nil
    end
    details
  end

  def misapplication?
    cites_misapplied == 't'
  end

  # graphql does not like question marks
  def is_misapplication
    misapplication?
  end

  def pro_parte?
    Rails.logger.debug("CRS#pro_parte?")
    # Follow misapplication pattern
    if cites_instance_id == 0
      false
    else
      pp = Instance.find(cites_instance_id).instance_type.pro_parte
      pp == 't' || pp == true
    end
  end

  def is_pro_parte
    pro_parte?
  end

  def source_object
    'nos'
  end
end
