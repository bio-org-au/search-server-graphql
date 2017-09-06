class NameSearch
  attr_reader :name_search_results
  # The returned object must respond to the "names" method call.
  def self.new(args)
    @args = args
    @parser = Search::Parser.new(args)
    search
  end

  # The returned object must respond to the "names" method call
  # because this method's result is returned by the new method.
  def self.search
    Rails.logger.debug("@parser.sci_cult_or_common: #{@parser.sci_cult_or_common} =========================================")
    @name_search_results = NameSearchResults.new
    if @parser.run_search?
      if @parser.scientific?
        Rails.logger.debug('Search#search scientific =======================================')
        scientific_search
      elsif @parser.cultivar?
        Rails.logger.debug('Search#search cultivar =======================================')
        cultivar_search
      elsif @parser.scientific_or_cultivar?
        Rails.logger.debug('Search#search scientific_or_cultivar =======================================')
        scientific_or_cultivar_search
      elsif @parser.common?
        Rails.logger.debug('Search#search common =======================================')
        common_search
      else
        Rails.logger.debug('Search#search else scientific =======================================')
        scientific_search
      end
      Rails.logger.debug('Search#search start =======================================')
    end
    Rails.logger.debug('Search#search end   ==========================================')
    @name_search_results
  end

  def self.scientific_search
    Rails.logger.debug('Search#search scientific_search =================================')
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
        .each do |name|
      @name_search_results.push name
    end
  end

  def self.cultivar_search
    Rails.logger.debug('Search#search cultivar_search =================================')
    Name.where(['lower(simple_name) like lower(?) or lower(full_name) like lower(?)', preprocessed_search_term, preprocessed_search_term])
        .joins(:name_type)
        .where('name_type.cultivar and not name_type.deprecated')
        .joins(:name_rank)
        .joins(:name_status)
        .joins(:name_tree_paths)
        .where("name_tree_path.tree_id = (select id from tree_arrangement where label = (select value from shard_config where name = 'name tree label'))")
        .where('exists (select null from instance where instance.name_id = name.id)')
        .select('name.*, name_status.name name_status_name')
        .ordered_scientifically
        .limit(@args['limit'] || 100)
        .each do |name|
      @name_search_results.push name
    end
  end

  def self.scientific_or_cultivar_search
    Rails.logger.debug('Search#search scientific_or_cultivar_search =================================')
    Name.where(['lower(simple_name) like lower(?) or lower(full_name) like lower(?)', preprocessed_search_term, preprocessed_search_term])
        .joins(:name_type)
        .where('(name_type.scientific or name_type.cultivar) and not name_type.deprecated')
        .joins(:name_rank)
        .joins(:name_status)
        .joins(:name_tree_paths)
        .where("name_tree_path.tree_id = (select id from tree_arrangement where label = (select value from shard_config where name = 'name tree label'))")
        .where('exists (select null from instance where instance.name_id = name.id)')
        .select('name.*, name_status.name name_status_name')
        .ordered_scientifically
        .limit(@args['limit'] || 100)
        .each do |name|
      @name_search_results.push name
    end
  end

  def self.common_search
    Rails.logger.debug('Search#search common_search =================================')
    Name.where(['lower(simple_name) like lower(?) or lower(full_name) like lower(?)', preprocessed_search_term, preprocessed_search_term])
        .joins(:name_type)
        .where("name_type_id in (select id from name_type where name_type.name in ('common','informal'))")
        .where('exists (select null from instance where instance.name_id = name.id)')
        .joins(:name_status)
        .select('name.*, name_status.name name_status_name')
        .order('full_name')
        .limit(@args['limit'] || 100)
        .each do |name|
      @name_search_results.push name
    end
  end

  def self.preprocessed_search_term
    if @args['search_term'].blank?
      ''
    elsif @parser.add_trailing_wildcard?
      @args['search_term'].sub(/$/, '%').tr('*', '%')
    else
      @args['search_term'].tr('*', '%')
    end
  end
end
