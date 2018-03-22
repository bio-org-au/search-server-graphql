# frozen_string_literal: true

# String methods
module SearchableNameStrings
  refine String do
    def regexified
      gsub("*", ".*").gsub("%", ".*").sub(/$/, "$").sub(/^/, "^")
    end

    def hybridized
      strip.gsub(/  */, " (x )?").sub(/^ */, "(x )?").tr("×", "x")
    end
  end
end

# Rails model
class AcceptedName < ActiveRecord::Base
  using SearchableNameStrings
  self.table_name = "accepted_name_vw"
  self.primary_key = "id"
  ACCEPTED_TREE_ACCEPTED = "ApcConcept"
  ACCEPTED_TREE_EXCLUDED = "ApcExcluded"
  SIMPLE_NAME_REGEX = "lower(f_unaccent(simple_name)) ~ lower(f_unaccent(?)) "
  FULL_NAME_REGEX = "lower(f_unaccent(full_name)) ~ lower(f_unaccent(?)) "
  belongs_to :status, class_name: "NameStatus", foreign_key: "name_status_id"
  belongs_to :rank, class_name: "NameRank", foreign_key: "name_rank_id"
  belongs_to :reference
  belongs_to :instance
  belongs_to :name, foreign_key: :id
  has_one :accepted_tree_comment, through: :instance
  has_many :synonyms, through: :instance
  has_many :names, through: :synonyms
  has_many :instance_types, through: :synonyms
  has_many :instance_notes, through: :instance
  has_many :instance_note_keys, through: :instance_notes
  has_many :cites, through: :synonyms
  has_many :cite_references, through: :synonyms, source: :reference
  scope :simple_name_like, (lambda do |string|
    where("lower(simple_name) like lower(?) ", string.tr("*", "%").downcase)
  end)
  scope :full_name_like, (lambda do |string|
    where("lower(full_name) like lower(?) ", string.tr("*", "%").downcase)
  end)
  scope :name_matches, (lambda do |string|
    where("#{SIMPLE_NAME_REGEX} or #{FULL_NAME_REGEX}",
          string.hybridized.regexified,
          string.hybridized.regexified)
  end)
  scope :ordered, -> { order("sort_name") }
  scope :accepted, -> { where(type_code: ACCEPTED_TREE_ACCEPTED) }
  scope :excluded, -> { where(type_code: ACCEPTED_TREE_EXCLUDED) }

  def show_status?
    status.show?
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
    status.name
  end

  def record_type
    if accepted_accepted?
      'accepted-name'
    elsif accepted_excluded?
      'excluded-name'
    else
      'unknown'
    end
  end

  def reference_citation
    reference.citation
  end

  def accepted_taxon_comment
    note_key_name_for_shard = "#{ShardConfig.tree_label} Comment"
    note_keys = InstanceNoteKey.where(name: note_key_name_for_shard)
    return nil if note_keys.blank?
    InstanceNote.where(instance_id: instance_id).where(instance_note_key_id: note_keys.first.id).try('first').try('value')
  end

  def accepted_taxon_distribution
    note_key_name_for_shard = "#{ShardConfig.tree_label} Dist."
    note_keys = InstanceNoteKey.where(name: note_key_name_for_shard)
    return nil if note_keys.blank?
    InstanceNote.where(instance_id: instance_id).where(instance_note_key_id: note_keys.first.id).try('first').try('value')
  end

  def cross_referenced_full_name
  end

  def cross_referenced_full_name_id
  end

  def synonyms
    Taxonomy::Search::Synonyms.new(instance_id)
  end

  def cross_reference_misapplication_details
  end

  def misapplication?
    cites_misapplied
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

  def order_string
    sort_name
  end

  def source_object
    'acn'
  end
end
