# frozen_string_literal: true

# Generate the sql to answer a request.
class Name::Search::SqlGenerator
  attr_reader :sql
  SIMPLE_NAME = 'lower(f_unaccent(simple_name)) like lower(f_unaccent(?))'
  FULL_NAME = 'lower(f_unaccent(name.full_name)) like lower(f_unaccent(?))'
  NAME_INSTANCE = '(select null from instance where instance.name_id = name.id)'
  INSTANCE_EXISTS = "exists #{NAME_INSTANCE}"
  NAME_ID = '(select id from name fn where lower(fn.simple_name) like lower(?))'
  NAME_TREE_PATH_FAMILY = "name_tree_path.family_id in (#{NAME_ID})"
  TREE_LABEL = "(select value from shard_config where name = 'name tree label')"
  TREE_ID = "(select id from tree_arrangement where label = #{TREE_LABEL})"
  NAME_TREE = "name_tree_path.tree_id = #{TREE_ID}"

  def initialize(parser)
    @parser = parser
    @name_type_clause = Name::Search::NameTypeClause.new(@parser).clause
    search_sql
  end

  def search_sql
    @sql = base_query
    add_name_type
    add_name
    add_author
    add_name_tree_path unless @parser.common?
    add_family unless @parser.common?
    add_genus
    add_rank
    add_select
    add_limit
    order_scientifically unless @parser.common?
    order_by_name if @parser.common?
    Rails.logger.debug("@sql: #{@sql.to_sql}")
  end

  def count
    @count_sql = Name.joins(:name_type).joins(:name_rank).where(@name_type_clause)
                    .where(INSTANCE_EXISTS)
    unless @parser.args['search_term'].blank?
      @count_sql = @count_sql.where([name_clause, preprocessed_search_term,
                                   preprocessed_search_term])
    end
    @count_sql = @count_sql.joins(:name_tree_paths).where(NAME_TREE)
    count_author
    count_family
    count_genus
    count_rank
    @count_sql.count
  end

  def count_author
    return if @parser.args['author_abbrev'].blank?
    @count_sql = @count_sql.joins(:author).where(['lower(author.abbrev) like lower(?)',
                                      @parser.args['author_abbrev']])
  end

  def count_family
    return if @parser.args['family'].blank?
    @count_sql = @count_sql.where([NAME_TREE_PATH_FAMILY, @parser.args['family']])
  end

  def count_genus
    return if @parser.args['genus'].blank?
    @count_sql = @count_sql.where(["name_rank.sort_order > (select sort_order from name_rank where name = 'Genus') and lower(name.simple_name) like lower(?)", @parser.args['genus']+' %'])
  end

  def count_rank
    return if @parser.args['rank'].blank?
    @count_sql = @count_sql.where(["name_rank.id = (select id from name_rank where lower(abbrev) = lower(?))", @parser.args['rank']])
  end

  def base_query
    Name.joins(:name_type).joins(:name_rank).joins(:name_status)
        .where(INSTANCE_EXISTS)
  end

  def add_select
    @sql = @sql.select('name.*, name_status.name name_status_name')
  end

  def add_limit
    @sql = @sql.limit(@parser.args['limit'] || 100)
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
    @sql = @sql.joins(:author).where(['lower(author.abbrev) like lower(?)',
                                      @parser.args['author_abbrev']])
  end

  def add_family
    return if @parser.args['family'].blank?
    @sql = @sql.where([NAME_TREE_PATH_FAMILY, @parser.args['family']])
  end

  def add_genus
    return if @parser.args['genus'].blank?
    @sql = @sql.where(["name_rank.sort_order > (select sort_order from name_rank where name = 'Genus') and lower(name.simple_name) like lower(?)", @parser.args['genus']+' %'])
  end

  def add_rank
    return if @parser.args['rank'].blank?
    @sql = @sql.where(["name_rank.id = (select id from name_rank where lower(abbrev) = lower(?))", @parser.args['rank']])
  end

  def add_name
    return if @parser.args['search_term'].blank?
    @sql = @sql.where([name_clause,
                       preprocessed_search_term,
                       preprocessed_search_term])
  end

  def name_clause
    "#{SIMPLE_NAME} or #{FULL_NAME}"
  end

  def add_name_type
    @sql = @sql.where(@name_type_clause)
  end

  def add_name_tree_path
    @sql = @sql.joins(:name_tree_paths)
               .where(NAME_TREE)
  end

  def order_scientifically
    @sql = @sql.ordered_scientifically
  end

  def order_by_name
    @sql = @sql.order('lower(name.full_name)')
  end
end
