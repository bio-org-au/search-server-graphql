# frozen_string_literal: true

# Add a filter to the sql to answer a request.
class Name::Search::Engines::Advanced::Filters::SearchTerm
  PARAMETER = 'search_term'

  def initialize(incoming_sql, parser)
    @incoming_sql = incoming_sql
    @parser = parser
  end

  def sql
    return @incoming_sql if parameter.blank?
    @incoming_sql.name_matches(parameter)
  end

  def parameter
    return nil unless @parser.text_arg?(PARAMETER)
    @parser.args[PARAMETER].strip.tr('*', '%').gsub(/×/, 'x')
  end
end
