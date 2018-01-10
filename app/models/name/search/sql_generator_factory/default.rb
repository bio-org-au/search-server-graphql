# frozen_string_literal: true

# Generate the sql to answer a request.
class Name::Search::SqlGeneratorFactory::Default
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
  TAXON_NAME_AUTHOR_ABBREV_CLAUSE = '( author_id in (select id from author where lower(abbrev) like lower(?)) or ex_author_id in (select id from author where abbrev like lower(?)) )'
  BASIONYM_AUTHOR_ABBREV_CLAUSE = '( base_author_id in (select id from author where lower(abbrev) like lower(?)) or ex_base_author_id in (select id from author where abbrev like lower(?)) )'
  # Genus
  GENUS_SO_SQL = "select sort_order from name_rank where name = 'Genus'"
  RANK_GENUS_CLAUSE = "name_rank.sort_order >= (#{GENUS_SO_SQL})"
  SIMPLE_NAME_CLAUSE = 'lower(name.simple_name) like lower(?)'
  GENUS_CLAUSE = "#{RANK_GENUS_CLAUSE} and #{SIMPLE_NAME_CLAUSE}"
  # Publication
  PROTOLOGUE_CLAUSE = "instance.instance_type_id in (select id from instance_type where protologue)"
  # Name element
  NAME_ELEMENT_CLAUSE = '(lower(unaccent(name_element)) like lower(unaccent(?)))'
  # Species
  # For species we want to match the species-search-term with
  # - "Genus species-search-term subsp. xyz" 
  # - "Genus species-search-term"
  # For species we want to exclude:
  # - "Genus species-search-termWith-some-extra-text subsp. xyz" 
  #
  # (They can always add their own wildcards.)
  SPECIES_CLAUSE = "#{SIMPLE_NAME_CLAUSE} or #{SIMPLE_NAME_CLAUSE}"
  # Rank
  RANK_CLAUSE =
    'name_rank.id = (select id from name_rank where lower(name) = lower(?))'
  RANK_AND_BELOW_CLAUSE =
    "name_rank.id in (select id from name_rank where sort_order >= (select sort_order from name_rank nrs where lower(nrs.name) = lower(?)) and sort_order < (select sort_order from name_rank where name = '[n/a]'))"

  def initialize(parser)
    @parser = parser
    @name_type_clause = Name::Search::NameTypeClause.new(@parser).clause
    search_sql
  end

  def search_sql
    @sql = base_query
    @sql = add_instance(@sql)
    @sql = add_name_type(@sql)
    @sql = add_name(@sql)
    add_taxon_name_author_abbrev
    add_basionym_author_abbrev
    @sql = add_name_tree_path(@sql) unless @parser.common?
    add_family unless @parser.common?
    add_genus
    add_species
    @sql = add_publication(@sql)
    @sql = add_publication_year(@sql)
    @sql = add_rank(@sql)
    add_name_element
    add_select
    add_limit
    add_offset
    add_includes
    order_scientifically unless @parser.common?
    order_by_name if @parser.common?
  end

  def count
    @cql = base_query
    @cql = add_instance(@cql)
    @cql = add_name_type(@cql)
    @cql = add_name(@cql)
    count_taxon_name_author_abbrev
    count_basionym_author_abbrev
    @cql = count_name_tree_path(@cql) unless @parser.common?
    count_family unless @parser.common?
    count_genus
    count_species
    @cql = add_publication(@cql)
    @cql = add_publication_year(@cql)
    @cql = add_rank(@cql)
    count_name_element
    @cql = @cql.select('distinct(name.id)')
    @cql = @cql.count
  end

  def add_includes
    @sql = @sql.includes(:name_type)
               .includes(:name_rank)
               .includes(:name_status)
               .includes(:name_tree_paths)
  end

  def add_taxon_name_author_abbrev
    return if taxon_name_author_abbrev_string.blank?
    @sql = @sql.where([TAXON_NAME_AUTHOR_ABBREV_CLAUSE,
                       taxon_name_author_abbrev_string,
                       taxon_name_author_abbrev_string])
  end

  def add_basionym_author_abbrev
    return if basionym_author_abbrev_string.blank?
    @sql = @sql.where([BASIONYM_AUTHOR_ABBREV_CLAUSE,
                       basionym_author_abbrev_string,
                       basionym_author_abbrev_string])
  end

  def count_taxon_name_author_abbrev
    return if taxon_name_author_abbrev_string.blank?
    @cql = @cql.where([TAXON_NAME_AUTHOR_ABBREV_CLAUSE,
                      taxon_name_author_abbrev_string,
                      taxon_name_author_abbrev_string])
  end

  def count_basionym_author_abbrev
    return if basionym_author_abbrev_string.blank?
    @cql = @cql.where([BASIONYM_AUTHOR_ABBREV_CLAUSE,
                       basionym_author_abbrev_string,
                       basionym_author_abbrev_string])
  end

  def taxon_name_author_abbrev_string
    return nil if @parser.args['taxon_name_author_abbrev'].blank?
    return nil if @parser.args['taxon_name_author_abbrev'].strip.blank?
    cleaned(@parser.args['taxon_name_author_abbrev'])
  end

  def basionym_author_abbrev_string
    return nil if @parser.args['basionym_author_abbrev'].blank?
    return nil if @parser.args['basionym_author_abbrev'].strip.blank?
    cleaned(@parser.args['basionym_author_abbrev'])
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

  def add_publication(sql)
    return sql if publication_string.blank?
    sql = sql.joins(:instances).joins(instances: :reference).merge(Reference.search_citation_text_for(publication_string))
    if @parser.args['protologue'] == '1'
      sql = sql.where(PROTOLOGUE_CLAUSE)
    end
    sql
  end

  def add_publication_year(sql)
    return sql if publication_year_string.blank?
    sql = sql.joins(:instances).joins(instances: :reference).merge(Reference.where(year: publication_year_string.to_i))
    if @parser.args['protologue'] == '1'
      sql = sql.where(PROTOLOGUE_CLAUSE)
    end
    sql
  end

  def publication_string
    return nil if @parser.args['publication'].blank?
    return nil if @parser.args['publication'].strip.blank?
    cleaned(@parser.args['publication'], false)
  end

  def publication_year_string
    return nil if @parser.args['publication_year'].blank?
    return nil if @parser.args['publication_year'].strip.blank?
    cleaned(@parser.args['publication_year'], false)
  end

  def add_species
    return if species_string.blank?
    @sql = @sql.where([SPECIES_CLAUSE,
                       "% #{species_string} %",
                       "% #{species_string}"])
  end

  def count_species
    return if species_string.blank?
    @cql = @cql.where([SPECIES_CLAUSE,
                       "% #{species_string} %",
                       "% #{species_string}"])
  end

  def species_string
    return nil if @parser.args['species'].blank?
    return nil if @parser.args['species'].strip.blank?
    cleaned(@parser.args['species'])
  end

  def add_rank(sql)
    return sql if rank_string.blank?
    if @parser.args['include_ranks_below'] == 'true'
      sql = sql.where([RANK_AND_BELOW_CLAUSE, rank_string])
    else
      sql = sql.where([RANK_CLAUSE, rank_string])
    end
    sql
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

  # Users dont like the name 'epithet' and it actually looks at
  # the name element column.
  def name_element_string
    return nil if @parser.args['name_element'].blank?
    return nil if @parser.args['name_element'].strip.blank?
    cleaned(@parser.args['name_element'])
  end

  def base_query
    Name.joins(:name_type).joins(:name_rank).joins(:name_status)
  end

  def add_instance(sql)
    if @parser.type_note_text.blank?
      sql = sql.joins(:instances)
    else
      add_instance_with_type_note_restriction(sql)
    end
    sql
  end

  def add_instance_with_type_note_restriction(sql)
    sql.where(["exists ( select null from instance where instance.name_id =  name.id and exists (select null from instance_note inote where lower(value) like lower(?) and inote.instance_id = instance.id and inote.instance_note_key_id in (select id from instance_note_key ink where ink.name in (#{list_of_type_notes_allowed}))))", '%' + @parser.type_note_text + '%'])
  end

  def list_of_type_notes_allowed
    note_types = []
    note_types.push "'Type'" if @parser.type_note_type?
    note_types.push "'Neotype'" if @parser.type_note_neotype?
    note_types.push "'Lectotype'" if @parser.type_note_lectotype?
    note_types.join(',')
  end

  def add_select
    @sql = @sql.select('name.*, name_status.name name_status_name')
  end

  def add_limit
    @sql = @sql.limit(@parser.args['limit'] || 100)
  end

  def add_offset
    return if @parser.args['offset'].blank?
    @sql = @sql.offset(@parser.offset)
  end

  def preprocessed_search_term
    return @pp_search_term if @pp_search_term.present?
    @pp_search_term = cleaned(@parser.args['search_term'],
                              @parser.add_trailing_wildcard)
  end

  def cleaned(term, fuzzy = false)
    return nil if term.nil?
    return nil if term.strip.blank?
    if fuzzy
      term.strip.tr('*', '%').sub(/$/, '%')
    else
      term.strip.tr('*', '%')
    end
  end

  def add_name(sql)
    return sql if @parser.args['search_term'].blank?
    sql.where([name_clause,
               preprocessed_search_term,
               preprocessed_search_term])
  end

  def name_clause
    "#{SIMPLE_NAME} or #{FULL_NAME}"
  end

  def add_name_type(sql)
    sql = sql.where(@name_type_clause)
  end

  def add_name_tree_path(sql)
    sql.joins(:name_tree_paths)
       .where(NAME_TREE)
  end


  def count_name_tree_path(sql)
    sql.joins(:name_tree_paths)
       .where(NAME_TREE)
  end

  def order_scientifically
    @sql = @sql.ordered_scientifically
  end

  def order_by_name
    @sql = @sql.order('lower(name.full_name)')
  end
end
