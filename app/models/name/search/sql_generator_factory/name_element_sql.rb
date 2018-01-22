# frozen_string_literal: true

# Generate the sql to answer a request
# that has a name element value.
class Name::Search::SqlGeneratorFactory::NameElementSql
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
  AUTHOR_ABBREV_CLAUSE = 'lower(author.abbrev) like lower(?)'
  # Genus
  GENUS_SO_SQL = "select sort_order from name_rank where name = 'Genus'"
  RANK_GENUS_CLAUSE = "name_rank.sort_order >= (#{GENUS_SO_SQL})"
  SIMPLE_NAME_CLAUSE = ' lower(name.simple_name) like lower(?)'
  GENUS_CLAUSE = "#{RANK_GENUS_CLAUSE} and #{SIMPLE_NAME_CLAUSE}"
  # Publication
  CIT_SQL = 'select id from reference where lower(citation) like lower(?)'
  PUBLICATION_CLAUSE = "instance.reference_id in (#{CIT_SQL})"
  # Name element

  NAME_ELEMENT_CLAUSE = 'lower(name_element) like lower(?)'
  # Species
  SPECIES_SORT_ORDER = "select sort_order from name_rank where name = 'Species'"
  RANK_IS_SPECIES = "name_rank.sort_order = (#{SPECIES_SORT_ORDER})"
  SPECIES_CLAUSE = "#{RANK_IS_SPECIES} and #{NAME_ELEMENT_CLAUSE}"
  # Rank
  RANK_CLAUSE =
    'name_rank.id = (select id from name_rank where lower(abbrev) = lower(?))'

  def initialize(parser)
    @parser = parser
    @name_type_clause = Name::Search::NameTypeClause.new(@parser).clause
    search_sql
  end

  def search_sql
    Rails.logger.debug('search_sql')
    @sql = []
    # ActiveRecord::Base.connection.select_all(base_query).each do |x|
    # ActiveRecord::Base.connection.select_all(Name.select_with_args(base_query_sql, @parser.args['name_element'] + '%')).each do |x|
    ActiveRecord::Base.connection.select_all(base_query).each do |x|
      Rails.logger.debug('search_sql loop')
      @sql.push(OpenStruct.new(x))
    end
    Rails.logger.debug('search_sql end')
    # @sql
  end

  def xxxx
    add_name_type
    add_name
    add_author_abbrev
    add_name_tree_path unless @parser.common?
    add_family unless @parser.common?
    add_genus
    add_species
    add_publication
    add_rank
    # add_name_element
    add_select
    add_limit
    order_scientifically unless @parser.common?
    order_by_name if @parser.common?
  end

  def count
    33
  end

  def xcount
    @cql = Name.joins(:name_type).joins(:name_rank).where(@name_type_clause)
               .where(INSTANCE_EXISTS)
    unless @parser.args['search_term'].blank?
      @cql = @cql.where([name_clause, preprocessed_search_term,
                         preprocessed_search_term])
    end
    @cql = @cql.joins(:name_tree_paths).where(NAME_TREE)
    count_author_abbrev
    count_family
    count_genus
    count_species
    count_publication
    count_rank
    count_name_element
    @cql.count
  end

  def base_query
    Rails.logger.debug('base_query')
    # Rails.logger.debug(Name.select_with_args(base_query_sql, @parser.args['name_element']))
    # Name.select_with_args(base_query_sql, 'distans')
    Name.select_with_args(base_query_sql, @parser.args['name_element'])
  end

  def xbase_query
    Name.joins(:name_type).joins(:name_rank).joins(:name_status)
        .where('lower(unaccent(name_element) like lower(unaccent(?))', @parser.args['name_element'] + '%')
        .select('name.id')
  end
  # .where(INSTANCE_EXISTS)

  def add_author_abbrev
    return if author_abbrev_string.blank?
    @sql = @sql.joins(:author).where([AUTHOR_ABBREV_CLAUSE,
                                      author_abbrev_string])
  end

  def count_author_abbrev
    return if author_abbrev_string.blank?
    @cql = @cql.joins(:author).where([AUTHOR_ABBREV_CLAUSE,
                                      author_abbrev_string])
  end

  def author_abbrev_string
    return nil if @parser.args['author_abbrev'].blank?
    return nil if @parser.args['author_abbrev'].strip.blank?
    cleaned(@parser.args['author_abbrev'])
  end

  def add_family
    return if family_string.blank?
    @sql = @sql.where([NAME_TREE_PATH_FAMILY, family_string])
  end

  def count_family
    return if family_string.blank?
    @cql = @cql.where([NAME_TREE_PATH_FAMILY, family_string])
  end

  def family_string
    return nil if @parser.args['family'].blank?
    return nil if @parser.args['family'].strip.blank?
    cleaned(@parser.args['family'])
  end

  def add_genus
    return if genus_string.blank?
    @sql = @sql.where([GENUS_CLAUSE, genus_string])
  end

  def count_genus
    return if genus_string.blank?
    @cql = @cql.where([GENUS_CLAUSE, genus_string])
  end

  # Add space plus wildcard to match "genus species-element"
  # e.g. user supplies 'poa' and we want it to match 'poa blah'
  def genus_string
    return nil if @parser.args['genus'].blank?
    return nil if @parser.args['genus'].strip.blank?
    "#{cleaned(@parser.args['genus'])}%"
  end

  def add_publication
    return if publication_string.blank?
    @sql = @sql.joins(:instances).where([PUBLICATION_CLAUSE,
                                         "#{publication_string}%"])
  end

  def count_publication
    return if publication_string.blank?
    @cql = @cql.joins(:instances).where([PUBLICATION_CLAUSE,
                                         "#{publication_string}%"])
  end

  def publication_string
    return nil if @parser.args['publication'].blank?
    return nil if @parser.args['publication'].strip.blank?
    cleaned(@parser.args['publication'])
  end

  def add_species
    return if species_string.blank?
    @sql = @sql.where([SPECIES_CLAUSE,
                       "#{species_string}%"])
  end

  def count_species
    return if species_string.blank?
    @cql = @cql.where([SPECIES_CLAUSE,
                       "#{species_string}%"])
  end

  def species_string
    return nil if @parser.args['species'].blank?
    return nil if @parser.args['species'].strip.blank?
    cleaned(@parser.args['species'])
  end

  def add_rank
    return if rank_string.blank?
    @sql = @sql.where([RANK_CLAUSE, rank_string])
  end

  def count_rank
    return if rank_string.blank?
    @cql = @cql.where([RANK_CLAUSE, rank_string])
  end

  def rank_string
    return nil if @parser.args['rank'].blank?
    return nil if @parser.args['rank'].strip.blank?
    cleaned(@parser.args['rank'], false)
  end

  def add_name_element
    return if name_element_string.blank?
    @sql = @sql.where([NAME_ELEMENT_CLAUSE, name_element_string])
  end

  def count_name_element
    return if @parser.args['name_element'].blank?
    @cql = @cql.where([NAME_ELEMENT_CLAUSE, name_element_string])
  end

  # Users don't like the name 'epithet' and it actually looks at
  # the name element column.
  def name_element_string
    return nil if @parser.args['name_element'].blank?
    return nil if @parser.args['name_element'].strip.blank?
    cleaned(@parser.args['name_element'])
  end

  def base_query_sql
    <<~HEREDOC
          select inner_name.*
      from
      (
      SELECT name.id, name.author_id, name.simple_name, name.full_name, name_status.name name_status_name, name_type.scientific
        FROM name
       INNER JOIN name_type
          ON name_type.id = name.name_type_id
       INNER JOIN name_status
          ON name_status.id = name.name_status_id
       INNER JOIN name_rank
          ON name_rank.id = name.name_rank_id
       INNER JOIN name_tree_path
          ON name_tree_path.name_id = name.id
       WHERE lower(f_unaccent(name_element)) like lower(f_unaccent(?))
      order by coalesce(trim( trailing '>' from substring(substring( name_tree_path.rank_path from 'Familia:[^>]*>') from 9)), 'A'||to_char(name_rank.sort_order, '0009')), sort_name, name_rank.sort_order
       ) inner_name
      where scientific
       limit 20
      HEREDOC
  end

  def preprocessed_search_term
    return @pp_search_term if @pp_search_term.present?
    @pp_search_term = cleaned(@parser.args['search_term'],
                              @parser.add_trailing_wildcard)
    throw 'no search term' if @parser.args['search_term'].blank?
  end

  def cleaned(term, fuzzy = true)
    return nil if term.nil?
    return nil if term.strip.blank?
    if fuzzy
      term.strip.tr('*', '%').sub(/$/, '%')
    else
      term.strip.tr('*', '%')
    end
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
