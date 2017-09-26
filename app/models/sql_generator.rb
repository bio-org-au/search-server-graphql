class SqlGenerator
  attr_reader :sql
  def initialize(parser)
    Rails.logger.debug('====================== SqlGenerator')
    Rails.logger.debug(%Q(author abbrev: #{parser.args["author_abbrev"]}))
    @parser = parser
    scientific_search_sql
  end

  def scientific_search_sql
    @sql = base_query
    add_name_type
    add_name
    add_author
  end

  def base_query
    Name.joins(:name_type)
        .joins(:name_rank)
        .joins(:name_status)
        .joins(:name_tree_paths)
        .where("name_tree_path.tree_id = (select id from tree_arrangement where label = (select value from shard_config where name = 'name tree label'))")
        .where('exists (select null from instance where instance.name_id = name.id)')
        .select('name.*, name_status.name name_status_name')
        .ordered_scientifically
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
    @sql = @sql.where(['lower(simple_name) like lower(?) or lower(name.full_name) like lower(?)', preprocessed_search_term, preprocessed_search_term])
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
             @sql.where('name_type.common')
           else
             throw 'Unknown name type'
           end
  end

  #def xsearch
    #Rails.logger.debug("@parser.sci_cult_or_common: #{@parser.sci_cult_or_common} =======")
    #@name_search_results = NameSearchResults.new
    #if @parser.run_search?
      #if @parser.scientific?
        #Rails.logger.debug('Search#search scientific =====')
        #scientific_search
      #elsif @parser.cultivar?
        #Rails.logger.debug('Search#search cultivar =====')
        #cultivar_search
      #elsif @parser.scientific_or_cultivar?
        #Rails.logger.debug('Search#search scientific_or_cultivar =====')
        #scientific_or_cultivar_search
      #elsif @parser.common?
        #Rails.logger.debug('Search#search common =====')
        #common_search
      #else
        #Rails.logger.debug('Search#search else scientific =====')
        #scientific_search
      #end
      #Rails.logger.debug('Search#search start =====')
    #end
    #Rails.logger.debug('Search#search end   ========')
    #@name_search_results
  #end
end
