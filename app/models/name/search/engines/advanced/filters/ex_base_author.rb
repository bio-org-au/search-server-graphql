# frozen_string_literal: true

# Add a filter to the sql to answer a request.
class Name::Search::Engines::Advanced::Filters::ExBaseAuthor
  PARAMETER = 'ex_base_author_abbrev'
  SFW = 'select id from author where '
  CLAUSE = "( name.ex_base_author_id in (#{SFW} lower(abbrev) like lower(?)))"

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
