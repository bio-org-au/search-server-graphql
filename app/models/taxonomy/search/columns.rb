# frozen_string_literal: true

# Provide a set of columns for a taxonomy select
class Taxonomy::Search::Columns
  attr_reader :instance_id
  def initialize(parser)
    @parser = parser
  end

  def build
    "name.id id, name.simple_name simple_name, name.full_name, \
    name.full_name_html, tree_element.excluded, \
    name_status.id name_status_id, \
    name_status.name name_status_name_, \
    instance_type.misapplied, \
    instance_type.pro_parte, \
    'dummy' cross_referenced_full_name, \
    -1 cross_referenced_full_name_id, \
    reference.citation reference_citation, \
    'xxx' accepted_taxon_comment, \
    'xxx' accepted_taxon_distribution, \
    tree_version_element.name_path name_path, \
    'xxx' source_object, \
    null cross_reference_misapplication_details, \
    null synonyms, \
    tree_element.instance_id, \
    instance.cites_id cites_id, \
    reference.id reference_id, \
    tree_element.profile profile, \
    tree_element.synonyms synonyms, \
    tree_version_element.name_path "
  end
end
