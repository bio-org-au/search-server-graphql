# frozen_string_literal: true

# Add a filter to the sql to answer a request.
class Name::Search::Engines::Advanced::Filters::Family
  PARAMETER = 'family'
  CLAUSE = 'name.family_id in (select id from name family where (lower(f_unaccent(family.simple_name)) like lower(f_unaccent(?))))'

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
    "#{@parser.args[PARAMETER].strip.tr('*', '%')}%"
  end
end
