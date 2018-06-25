# frozen_string_literal: true

# Provide a set of columns for a taxonomy select
class Taxonomy::Search::Columns
  attr_reader :instance_id
  def initialize(parser)
    @parser = parser
  end

  def build
    "name.id id, \
    name.simple_name simple_name, \
    name.full_name, \
    name.full_name_html, \
    tree_element.excluded, \
    name_status.id name_status_id, \
    name_status.name name_status_name_, \
    instance_type.misapplied, \
    instance_type.pro_parte, \
    'dummy' cross_referenced_full_name, \
    -1 cross_referenced_full_name_id, \
    reference.citation reference_citation, \
    null cross_reference_misapplication_details, \
    tree_element.instance_id, \
    instance.cites_id cites_id, \
    reference.id reference_id, \
    tree_version_element.name_path, \
    tree_element.profile profile, \
    tree_element.synonyms synonyms, \
    false cross_reference, \
    '' cross_ref_full_name_html, \
    false doubtful"
  end
end
