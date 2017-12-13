# frozen_string_literal: true

# Generate the sql to answer a request.
class Reference::Search::SqlGenerator
  attr_reader :sql
  DEFAULT_LIMIT = 20

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
  end

  def count
    @cql = base_query
    count_publication
    @cql.count
  end

  def base_query
    Reference.where("1=1")
  end

  def add_select
    @sql = @sql.select('reference.*')
  end

  def add_limit
    @sql = @sql.limit(@parser.args['limit'] || DEFAULT_LIMIT)
  end

  def add_publication
    @sql = @sql.where(['lower(citation) like lower(?)',publication])
  end

  def add_order
    @sql = @sql.order('year, citation')
  end

  def count_publication
    @cql = @cql.where(['lower(citation) like lower(?)',publication])
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
