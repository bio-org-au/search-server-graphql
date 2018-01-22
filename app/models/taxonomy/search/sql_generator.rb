# frozen_string_literal: true

# Produce sql for taxonomy queries.
class Taxonomy::Search::SqlGenerator
  attr_reader :sql
  def initialize(parser)
    Rails.logger.debug('====================== Taxonomy::Search::SqlGenerator')
    Rails.logger.debug(%(author abbrev: #{parser.args['author_abbrev']}))
    @parser = parser
    generate_sql
  end

  def generate_sql
    @sql = base_query
    add_name
    add_name_status
    add_instance
    # add_author
  end

  def base_query
    Name.select("name.id, name.full_name, name.simple_name, name_status.name \
                name_status_name, reference.citation reference_citation, \
                instance.id instance_id")
        .order('name.sort_name')
    # .ordered_scientifically
  end

  def preprocessed_search_term
    return @pp_search_term if @pp_search_term.present?
    throw 'no search term' if @parser.args['search_term'].blank?
    stripped_term = @parser.args['search_term'].strip
    @pp_search_term = if stripped_term.blank?
                        ''
                      elsif @parser.add_trailing_wildcard
                        stripped_term.sub(/$/, '%').tr('*', '%')
                      else
                        stripped_term.tr('*', '%')
                      end
  end

  def add_author
    return if @parser.args['author_abbrev'].blank?
    @sql = @sql.joins(:author)
               .where(['lower(author.abbrev) like lower(?)',
                       @parser.args['author_abbrev']])
  end

  def add_name
    return if @parser.args['search_term'].blank?
    @sql = @sql.where(["lower(f_unaccent(simple_name)) \
                        like lower(f_unaccent(?)) \
                        or lower(f_unaccent(name.full_name)) \
                        like lower(f_unaccent(?))",
                       preprocessed_search_term,
                       preprocessed_search_term])
  end

  def add_name_status
    @sql = @sql.joins(:name_status)
  end

  def add_instance
    @sql = @sql.joins(:instances)
    add_tree_node
    add_reference
  end

  def add_tree_node
    @sql = @sql.joins(tree_nodes: :tree_arrangement)
               .where(['tree_arrangement.label = ? ',
                       ShardConfig.classification_tree_key])
               .where(tree_node: { next_node_id: nil })
               .where.not(tree_node: { checked_in_at_id: nil })
               .where('instance.id = tree_node.instance_id')
  end

  def add_reference
    @sql = @sql.joins(instances: :reference)
  end
end
