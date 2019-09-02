# frozen_string_literal: true

# Add a filter to the sql to answer a request.
class Name::Search::Engines::Advanced::Filters::ExAuthor
  SELECT = 'select id from author where '
  CLAUSE = "( name.ex_author_id in (#{SELECT} lower(abbrev) like lower(?)))"
  PARAMETER = :ex_author_abbrev

  def initialize(incoming_sql, parser)
    @incoming_sql = incoming_sql
    @parser = parser
  end

  def sql
    return @incoming_sql if parameter.blank?

    @incoming_sql.where([CLAUSE, parameter])
  end

  def parameter
    return nil unless @parser.text_arg?(PARAMETER)

    @parser.args[PARAMETER].strip.tr('*', '%').gsub(/×/, 'x')
  end
end
