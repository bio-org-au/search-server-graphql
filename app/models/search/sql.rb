# frozen_string_literal: true

# Rails model
# Interpret GraphQL args and provided
# directions for the required search.
class Search::Sql
  attr_reader :search_term,

              def initialize(args, add_trailing_wildcard)
                @args = args
                @add_trailing_wildcard = add_trailing_wildcard
                scientific_search_sql
              end

  def scientific_search_sql
    Name.where(['lower(simple_name) like lower(?) or lower(full_name) like lower(?)', preprocessed_search_term, preprocessed_search_term])
        .joins(:name_type)
        .where('name_type.scientific and not name_type.deprecated')
        .joins(:name_rank)
        .joins(:name_status)
        .joins(:name_tree_paths)
        .where("name_tree_path.tree_id = (select id from tree_arrangement where label = (select value from shard_config where name = 'name tree label'))")
        .where('exists (select null from instance where instance.name_id = name.id)')
        .select('name.*, name_status.name name_status_name')
        .ordered_scientifically
        .limit(@args['limit'] || 100)
  end

  def preprocessed_search_term
    return @pp_search_term if @pp_search_term.present?
    stripped_term = @args['search_term'].strip
    @pp_search_term = if stripped_term.blank?
                        ''
                      elsif add_trailing_wildcard
                        stripped_term.sub(/$/, '%').tr('*', '%')
                      else
                        stripped_term.tr('*', '%')
                   end
  end
end
