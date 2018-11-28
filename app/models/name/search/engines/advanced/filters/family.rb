# frozen_string_literal: true

# Add a filter to the sql to answer a request.
class Name::Search::Engines::Advanced::Filters::Family
  PARAMETER = 'family'
  SELECT = 'select id from name family where '
  LFA = ' lower(f_unaccent'
  SIMPLE = " (#{LFA}(family.simple_name)) like #{LFA}(?)))"
  FULL = " (#{LFA}(family.full_name)) like #{LFA}(?)))"
  IN_FAMILY = "name.family_id in ( #{SELECT} #{SIMPLE} OR #{FULL})"
  ITSELF_SIMPLE = " (#{LFA}(name.simple_name)) like #{LFA}(?)))"
  ITSELF_FULL = " (#{LFA}(name.simple_name)) like #{LFA}(?)))"
  FAMILY_RANK = " name_rank.name = 'Familia' "
  THE_NAME_ITSELF = "((#{ITSELF_SIMPLE} OR #{ITSELF_FULL}) AND #{FAMILY_RANK})"
  CLAUSE = "(#{IN_FAMILY} OR #{THE_NAME_ITSELF})"

  def initialize(incoming_sql, parser)
    @incoming_sql = incoming_sql
    @parser = parser
    @param = parameter
  end

  def sql
    return @incoming_sql if @param.blank?

    @incoming_sql.where([CLAUSE, @param, @param, @param, @param])
  end

  def parameter
    return nil unless @parser.text_arg?(PARAMETER)

    "#{@parser.args[PARAMETER].strip.tr('*', '%')}%"
  end
end
