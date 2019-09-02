# frozen_string_literal: true

# Produce sql for taxonomy queries.
class Taxonomy::Search::SqlGeneratorFactory::CrossReference
  def initialize(parser)
    @parser = parser
  end

  def xsearch
    @core_search.joins(:name_status)
                .select('max(name.id) id, max(name.full_name) full_name')
                .select('max(name.full_name_html) full_name_html')
                .select('max(name.simple_name) simple_name')
                .select('max(instance.id) instance_id')
                .select('tree_element.excluded')
                .select('max(tree_version_element.name_path) name_path')
                .select('max(citer_instances_instance.id) citers_instance_id')
                .select('max(names_instance.simple_name) nisn')
                .select('max(name_status.name) name_status_name_')
                .select('instance_type.misapplied')
                .select('true cross_reference')
                .select('max(names_instance.id) cross_referenced_full_name_id')
                .select('max(names_instance.full_name) cross_referenced_full_name')
                .select('max(names_instance.full_name_html) cross_ref_full_name_html')
                .select('max(reference.citation) reference_citation')
                .select('instance_type.doubtful, instance_type.pro_parte')
                .group(main_group_by_columns)
                .limit(@parser.limit)
                .offset(@parser.offset)
  end

  # Try to match accepted + cross reference class
  def search
    @core_search.joins(:name_status)
                .select('max(name.id) id')
                .select('max(name.simple_name) simple_name')
                .select('max(name.full_name) full_name')
                .select('max(name.full_name_html) full_name_html')
                .select('tree_element.excluded')
                .select('max(name_status.id) name_status_id')
                .select('max(name_status.name) name_status_name_')
                .select('instance_type.misapplied')
                .select('instance_type.pro_parte')
                .select('max(names_instance.full_name) cross_referenced_full_name')
                .select('null cross_reference_misapplication_details')
                .select('max(names_instance.id) cross_referenced_full_name_id')
                .select('max(instance.id) instance_id')
                .select('max(citer_instances_instance.id) citers_instance_id')
                .select('max(tree_version_element.name_path) name_path')
                .select('null profile')
                .select('null synonyms')
                .select('true cross_reference')
                .select('max(names_instance.full_name_html) cross_ref_full_name_html')
                .select('instance_type.doubtful')
                .select('max(reference.citation) reference_citation')
                .group(main_group_by_columns)
                .limit(@parser.limit)
                .offset(@parser.offset)
                .order(' full_name ')
  end

  # core_search.size was giving the wrong result.
  # e.g. count of 14 for 8 'Angophora c' cross references
  def count
    size = 0
    core_search.group("name.id, #{main_group_by_columns}").each do |_x|
      size += 1
    end
    size
  end

  private

  def core_search
    @core_search ||= Name.name_matches(@parser.search_term)
                         .joins(instances: [{ cited_instance: :reference },
                                            { citer_instance:
                                              { name:
                                                { tree_elements:
                                                  { tree_version_elements:
                                                    { tree_version: :tree } } } } },
                                            :instance_type])
                         .where('tree.accepted_tree = true')
                         .where('tree_version.id = tree.current_tree_version_id')
  end

  def main_group_by_columns
    s = 'cited_instances_instance.id, instance_type.misapplied, '
    s += 'tree_element.excluded, instance_type.doubtful,'
    s += 'instance_type.pro_parte'
  end
end
