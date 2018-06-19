# frozen_string_literal: true

# Produce sql for taxonomy queries.
class Taxonomy::Search::SqlGeneratorFactory::AcceptedExcluded
  def initialize(parser)
    @parser = parser
  end

  def search
    @core_search.joins(:name_status)
                .select(Taxonomy::Search::Columns.new(@parser).build)
                .order("name_path")
                .limit(@parser.limit)
                .offset(@parser.offset)
  end

  def count
    core_search.size
  end

private

  def core_search
    @core_search ||= Name.joins(tree_elements: [{tree_version_elements: {tree_version: :tree}}, {instance: [:instance_type, :reference]}])
                         .name_matches(@parser.search_term)
                         .where("tree.accepted_tree = true and tree.current_tree_version_id = tree_version.id")
  end

end

