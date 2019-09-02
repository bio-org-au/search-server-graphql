# frozen_string_literal: true

# Produce sql for taxonomy queries.
class Taxonomy::Search::SqlGeneratorFactory::ExcludedCrossReference
  def initialize(parser)
    @parser = parser
  end

  def search
    Name.run_union_search(union_search,
                          'full_name',
                          @parser.limit,
                          @parser.offset)
  end

  def union_search
    excluded_core_search.joins(:name_status)
                        .select(Taxonomy::Search::Columns.new(@parser).build)
                        .union(cross_ref_search)
  end

  def count
    size = 0
    search.each do |_x|
      size += 1
    end
    size
  end

  private

  def excluded_core_search
    @core_search ||= Name.joins(tree_elements: [{ tree_version_elements: { tree_version: :tree } }, { instance: %i[instance_type reference] }])
                         .name_matches(@parser.search_term)
                         .where('tree.accepted_tree = true and tree.current_tree_version_id = tree_version.id')
                         .where('tree_element.excluded = true')
  end

  def cross_ref_search
    cross_ref_core_search.joins(:name_status)
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
                         .select('max(names_instance.id) cross_referenced_full_name_id')
                         .select('max(reference.citation) reference_citation')
                         .select('null cross_reference_misapplication_details')
                         .select('max(instance.id) instance_id')
                         .select('max(citer_instances_instance.id) citers_instance_id')
                         .select('0 reference_id')
                         .select('max(tree_version_element.name_path) name_path')
                         .select('null profile')
                         .select('null synonyms')
                         .select('true cross_reference')
                         .select('max(names_instance.full_name_html) cross_ref_full_name_html')
                         .select('instance_type.doubtful')
                         .group(main_group_by_columns)
  end

  def cross_ref_core_search
    @cross_ref_core_search ||= Name.name_matches(@parser.search_term)
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
