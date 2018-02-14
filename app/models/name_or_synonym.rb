# frozen_string_literal: true

# Rails model
class NameOrSynonym < ActiveRecord::Base
  self.table_name = "name_or_synonym_vw"
  APC_ACCEPTED = "ApcConcept"
  APC_EXCLUDED = "ApcExcluded"

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

    query2 = AcceptedSynonym.name_matches(search_term)
    sql = NameOrSynonym.connection.unprepared_statement do
      "((#{query1.to_sql}) UNION (#{query2.to_sql})) AS name_or_synonym_vw"
    end
    NameOrSynonym.from(sql)
                 .order("sort_name,
                         case cites_misapplied when true then 'Z' else 'A' end,
                         cites_cites_ref_year")
  end

  def accepted_accepted?
    type_code == APC_ACCEPTED
  end

  def accepted_excluded?
    type_code == APC_EXCLUDED
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
    Reference.find(reference_id).citation
  end

  def accepted_taxon_comment
    InstanceNote.where(instance_id: instance_id).where(instance_note_key_id: InstanceNoteKey.find_by(name: 'APC Comment').id).try('first').try('value')
  end

  def accepted_taxon_distribution
    InstanceNote.where(instance_id: instance_id).where(instance_note_key_id: InstanceNoteKey.find_by(name: 'APC Dist.').id).try('first').try('value')
  end

  def cross_referenced_full_name
    accepted_full_name
  end
end
