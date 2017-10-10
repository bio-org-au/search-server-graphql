class Name::Search::SqlGenerator
  attr_reader :sql
  def initialize(parser)
    Rails.logger.debug('====================== SqlGenerator')
    Rails.logger.debug(%Q(author abbrev: #{parser.args["author_abbrev"]}))
    @parser = parser
    search_sql
  end

  def search_sql
    @sql = base_query
    add_name_type
    add_name
    add_author
    add_name_tree_path unless @parser.common?
    order_scientifically unless @parser.common?
    order_by_name if @parser.common?
  end

  def base_query
    Name.joins(:name_type)
        .joins(:name_rank)
        .joins(:name_status)
        .where('exists (select null from instance where instance.name_id = name.id)')
        .select('name.*, name_status.name name_status_name')
        .limit(@parser.args['limit'] || 100)
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
    @sql = @sql.joins(:author).where(["lower(author.abbrev) like lower(?)", @parser.args["author_abbrev"]])
  end

  def add_name
    return if @parser.args['search_term'].blank?
    @sql = @sql.where(['lower(f_unaccent(simple_name)) like lower(f_unaccent(?)) or lower(f_unaccent(name.full_name)) like lower(f_unaccent(?))', preprocessed_search_term, preprocessed_search_term])
  end

  def add_name_type
    @sql = case 
           when @parser.scientific?
             @sql.where('name_type.scientific')
           when @parser.cultivar?
             @sql.where('name_type.cultivar')
           when @parser.scientific_or_cultivar?
             @sql.where('(name_type.cultivar or name_type.scientific)')
           when @parser.common?
             @sql.where("name_type.name in ('common','informal','vernacular')")
           else
             throw 'Unknown name type'
           end
  end

  def add_name_tree_path
    @sql = @sql.joins(:name_tree_paths)
               .where("name_tree_path.tree_id = (select id from tree_arrangement where label = (select value from shard_config where name = 'name tree label'))")
  end

  def order_scientifically
    @sql = @sql.ordered_scientifically
  end

  def order_by_name
    @sql = @sql.order("lower(name.full_name)")
  end
end
