# frozen_string_literal: true

# Add a filter to the sql to answer a request.
class Name::Search::Engines::Advanced::Filters::Species
  PARAMETER = 'species'

  # Species
  # For species we want to match the species-search-term with
  # - "Genus species-search-term subsp. xyz"
  # - "Genus species-search-term"
  # For species we want to exclude:
  # - "Genus species-search-termWith-some-extra-text subsp. xyz"
  #
  # (They can always add their own wildcards.)
  SIMPLE_NAME_CLAUSE = 'lower(name.simple_name) like lower(?)'
  CLAUSE = "#{SIMPLE_NAME_CLAUSE} or #{SIMPLE_NAME_CLAUSE}"

  def initialize(incoming_sql, parser)
    @incoming_sql = incoming_sql
    @parser = parser
  end

  def sql
    return @incoming_sql if parameter.blank?

    @incoming_sql.where([CLAUSE,
                         "% #{parameter} %",
                         "% #{parameter}"])
  end

  def parameter
    return nil unless @parser.text_arg?(PARAMETER)

    @parser.args[PARAMETER].strip.tr('*', '%').gsub(/×/, 'x')
  end
end
