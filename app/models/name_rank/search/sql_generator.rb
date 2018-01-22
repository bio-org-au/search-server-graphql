# frozen_string_literal: true

# Generate the sql to answer a request.
class NameRank::Search::SqlGenerator
  attr_reader :sql

  def initialize(parser)
    @parser = parser
    search_sql
  end

  def search_sql
    @sql = base_query
    add_publication
    add_limit
    add_select
    add_order
    Rails.logger.debug("@sql: #{@sql.to_sql}")
  end

  def count
    @cql = base_query
    count_publication
    @cql.count
  end

  def base_query
    NameRank.where('1=1')
  end

  def add_select
    @sql = @sql.select('name_rank.*')
  end

  def add_limit
    @sql = @sql.limit(@parser.args['limit'] || 10)
  end

  def add_publication
    @sql = @sql.where(['lower(citation) like lower(?)', publication])
  end

  def add_order
    @sql = @sql.order('year, citation')
  end

  def count_publication
    @cql = @cql.where(['lower(citation) like lower(?)', publication])
  end

  def publication
    cleaned(@parser.args['publication'])
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
end
