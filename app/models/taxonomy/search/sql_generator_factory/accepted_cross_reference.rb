# frozen_string_literal: true

# Produce sql for taxonomy queries.
class Taxonomy::Search::SqlGeneratorFactory::AcceptedCrossReference
  def initialize(parser)
    Rails.logger.debug('====================== Taxonomy::Search::SqlGeneratorFactory::AcceptedCrossReference')
    Rails.logger.debug(%(author abbrev: #{parser.args['author_abbrev']}))
    @parser = parser
  end

  def count
    sql = base_sql
    sql = sql.count
    sql
  end

  #def generate_sql
  def base_sql
    sql = Name.where("1=1")
    sql = add_name(sql)
    sql = add_name_status(sql)
    sql = add_instance(sql)
    sql = add_reference(sql)
    sql = add_tree_node(sql)
    Rails.logger.debug('=====')
    Rails.logger.debug(sql)
    Rails.logger.debug('=====')
    sql
  end

  def sql
    sql = base_sql
    sql = add_select(sql)
    sql = add_order(sql)
    sql = add_limit(sql)
    sql = add_offset(sql)
    sql
  end

  def add_select(sql)
    sql = sql.select("name.id, name.full_name, name.simple_name, name_status.name \
                name_status_name, reference.citation reference_citation, \
                instance.id instance_id")
  end

  def add_order(sql)
    sql = sql.order('name.sort_name')
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

  def add_name(sql)
    return if @parser.args['search_term'].blank?
    sql = sql.where(["lower(f_unaccent(simple_name)) \
                        like lower(f_unaccent(?)) \
                        or lower(f_unaccent(name.full_name)) \
                        like lower(f_unaccent(?))",
                       preprocessed_search_term,
                       preprocessed_search_term])
    sql
  end

  def add_name_status(sql)
    sql = sql.joins(:name_status)
  end

  def add_instance(sql)
    sql = sql.joins(:instances)
    add_tree_node(sql)
    add_reference(sql)
    sql
  end

  def add_tree_node(sql)
    sql = sql.joins(tree_nodes: :tree_arrangement)
               .where(['tree_arrangement.label = ? ',
                       ShardConfig.classification_tree_key])
               .where(tree_node: { next_node_id: nil })
               .where.not(tree_node: { checked_in_at_id: nil })
               .where('instance.id = tree_node.instance_id')
    sql
  end

  def add_reference(sql)
    sql = sql.joins(instances: :reference)
  end

  def add_limit(sql)
    sql = sql.limit(@parser.args['limit'] || 10)
  end

  def add_offset(sql)
    return sql if @parser.args['offset'].blank?
    sql = sql.offset(@parser.offset)
  end

end
