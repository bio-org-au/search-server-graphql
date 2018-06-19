# frozen_string_literal: true

# Produce sql for taxonomy queries.
class Taxonomy::Search::SqlGeneratorFactory::CrossReference
  def initialize(parser)
    @parser = parser
  end

  def search
    @core_search.joins(:name_status)
      .select("max(name.id) id, max(name.full_name) full_name")
      .select("max(name.full_name_html) full_name_html")
      .select("max(name.simple_name) simple_name")
      .select("max(instance.id) instance_id")
      .select("tree_element.excluded")
      .select("max(tree_version_element.name_path) name_path")
      .select("max(citer_instances_instance.id) citers_instance_id")
      .select("max(names_instance.simple_name) nisn")
      .select("max(name_status.name) name_status_name_")
      .select("instance_type.misapplied")
      .select("true cross_reference")
      .select("max(names_instance.full_name) cross_ref_full_name")
      .select("max(names_instance.full_name_html) cross_ref_full_name_html")
      .select("max(reference.citation) cited_ref_citation")
      .select("instance_type.doubtful, instance_type.pro_parte")
      .group("cited_instances_instance.id, instance_type.misapplied, tree_element.excluded, instance_type.doubtful, instance_type.pro_parte")
      .limit(@parser.limit)
      .offset(@parser.offset)
  end

  def count
    core_search.size
  end

private

  def core_search
    @core_search ||= Name.name_matches(@parser.search_term)
                         .joins(instances: [{cited_instance: :reference},
                                            {citer_instance:
                                              {name:
                                                {tree_elements:
                                                  {tree_version_elements:
                                                    {tree_version: :tree}
                                                  }
                                                }
                                              }
                                             },
                                             :instance_type])
                         .where("tree.accepted_tree = true")
                         .where("tree_version.id = tree.current_tree_version_id")
  end
end
