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
class CrossReferenceSynonym < ActiveRecord::Base
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
    order("sort_name,
          case cites_misapplied when true then 'Z'
          else 'A' end, cites_cites_ref_year, accepted_full_name, reference_id")
  end)
  scope :ordered, -> { order("sort_name") }

  def order_string
    "#{sort_name}#{case misapplication? when true then 'Z' else 'A' end}#{cites_cites_ref_year}#{accepted_full_name}"
  end

  def accepted_accepted?
    type_code == "ApcConcept"
  end

  def accepted_excluded?
    type_code == "ApcExcluded"
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
    Reference.find(cites_cites_ref_id).citation
  end
  
  def reference_id
    cites_cites_ref_id
  end

  def accepted_taxon_comment
  end

  def accepted_taxon_distribution
  end

  def cross_referenced_full_name
    accepted_full_name
  end

  def synonyms
    []
  end

  def misapplying_author_string_and_year
    return nil if reference_citation.nil?
    reference_citation.sub(/\),.*/,')')
  end

  def misapplication?
    Rails.logger.debug("CRS#misapplication?")
    Rails.logger.debug("CRS#misapplication?: cites_misapplied: #{cites_misapplied}")
    # Some confusing results - need to clarify.
    cites_misapplied == 't' || cites_misapplied == true
  end

  def is_misapplication
    misapplication?
  end

  def pro_parte?
    Rails.logger.debug("CRS#pro_parte?")
    # Follow misapplication pattern
    pp = Instance.find(cites_instance_id).instance_type.pro_parte
    pp == 't' || pp == true
  end

  def is_pro_parte
    pro_parte?
  end

  def cross_reference_misapplication_details
    if misapplication?
      citing_instance = Instance.find(cites_instance_id)

      details = OpenStruct.new
      details.citing_instance_id = citing_instance.id
      details.citing_reference_id = citing_instance.reference_id
      details.citing_reference_author_string_and_year = citing_instance.reference.author_string_and_year
      details.misapplying_author_string_and_year = misapplying_author_string_and_year
      details.pro_parte = citing_instance.instance_type.pro_parte
      details.is_doubtful = citing_instance.instance_type.doubtful?
    else
      details = nil
    end
    details
  end
 
  def source_object
    'crs'
  end
end
