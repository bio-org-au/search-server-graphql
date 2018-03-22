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
class AcceptedSynonym < ActiveRecord::Base
  using SearchableNameStrings
  self.table_name = "accepted_synonym_vw"
  self.primary_key = "id"
  SIMPLE_NAME_REGEX = "lower(f_unaccent(simple_name)) ~ lower(f_unaccent(?)) "
  FULL_NAME_REGEX = "lower(f_unaccent(full_name)) ~ lower(f_unaccent(?)) "
  belongs_to :synonym_type,
             class_name: "InstanceType",
             foreign_key: :synonym_type_id
  belongs_to :synonym_ref, class_name: "Reference", foreign_key: :synonym_ref_id
  belongs_to :synonym_name, class_name: "Name", foreign_key: :id
  belongs_to :synonym_cites,
             class_name: "Instance",
             foreign_key: :cites_instance_id
  belongs_to :status, class_name: "NameStatus", foreign_key: "name_status_id"
  scope :simple_name_like, (lambda do |string|
    where("lower((simple_name)) like lower((?)) ",
          string.tr("*", "%").downcase)
  end)
  scope :full_name_like, (lambda do |string|
    where("lower((full_name)) like lower((?)) ",
          string.tr("*", "%").downcase)
  end)
  scope :name_matches, (lambda do |string|
    where("#{SIMPLE_NAME_REGEX} or #{FULL_NAME_REGEX}",
          string.hybridized.regexified,
          string.hybridized.regexified)
  end)
  scope :default_ordered, (lambda do
    order("lower(simple_name),
          case cites_misapplied when true then 'Z'
          else 'A' end, cites_cites_ref_year")
  end)
  scope :ordered, -> { order("sort_name") }

  def accepted_accepted?
    type_code == NameOrSynonym.ACCEPTED_TREE_ACCEPTED
  end

  def accepted_excluded?
    type_code == NameOrSynonym.ACCEPTED_TREE_EXCLUDED
  end

  def synonym?
    type_code == "synonym"
  end

  def name_status_name
    status.name
  end

  def record_type
    'cross-reference'
  end
  
  def reference_citation
    'no reference citation'
  end

  def accepted_taxon_comment
  end

  def accepted_taxon_distribution
  end

  def cross_referenced_full_name
  end
end
