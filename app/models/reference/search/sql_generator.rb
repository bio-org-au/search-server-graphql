# frozen_string_literal: true

# Generate the sql to answer a request.
class Reference::Search::SqlGenerator
  attr_reader :sql
  DEFAULT_LIMIT = 20
  CIT_WHERE = "to_tsvector('english'::regconfig,citation::text) @@ to_tsquery(quote_literal(?))"

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
    Reference.where('1=1')
  end

  def add_select
    @sql = @sql.select('reference.*')
  end

  def add_limit
    @sql = @sql.limit(@parser.args['limit'] || DEFAULT_LIMIT)
  end

  def add_publication
    @sql = @sql.where([CIT_WHERE, publication.gsub(/  */, ' & ')])
  end

  def add_order
    @sql = @sql.order('year, citation')
  end

  def count_publication
    @cql = @cql.where(['lower(citation) like lower(?)', publication])
  end

  def publication
    not_fuzzy = false
    cleaned(@parser.args['publication'].delete('*'), not_fuzzy)
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
