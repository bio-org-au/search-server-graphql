# frozen_string_literal: true

# Add a filter to the sql to answer a request.
class Name::Search::Engines::Advanced::Filters::Genus
  PARAMETER = 'genus'
  GENUS_SO_SQL = "select sort_order from name_rank where name = 'Genus'"
  RANK_GENUS_CLAUSE = "name_rank.sort_order >= (#{GENUS_SO_SQL})"
  SIMPLE_NAME_CLAUSE = 'lower(name.simple_name) like lower(?)'
  CLAUSE = "#{RANK_GENUS_CLAUSE} and #{SIMPLE_NAME_CLAUSE}"

  def initialize(incoming_sql, parser)
    @incoming_sql = incoming_sql
    @parser = parser
  end

  def sql
    return @incoming_sql if parameter.blank?

    @incoming_sql.where([CLAUSE, parameter])
  end

  # Add space plus wildcard to match "genus species-element"
  # e.g. user supplies 'poa' and we want it to match 'poa blah'
  def parameter
    return nil unless @parser.text_arg?(PARAMETER)

    "#{@parser.args[PARAMETER].strip.tr('*', '%').gsub(/×/, 'x')}%"
  end
end
