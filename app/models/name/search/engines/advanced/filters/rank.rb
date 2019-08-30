# frozen_string_literal: true

# Add a filter to the sql to answer a request.
class Name::Search::Engines::Advanced::Filters::Rank
  PARAMETER = 'rank'
  CLAUSE =
    'name_rank.id = (select id from name_rank where lower(name) = lower(?))'
  RANK_AND_BELOW_CLAUSE =
    "name_rank.id in (select id from name_rank where sort_order >= (select sort_order from name_rank nrs where lower(nrs.name) = lower(?)) and sort_order < (select sort_order from name_rank where name = '[n/a]'))"

  def initialize(incoming_sql, parser)
    @incoming_sql = incoming_sql
    @parser = parser
  end

  def sql
    return @incoming_sql if parameter.blank?
    @incoming_sql = if @parser.args['includeRanksBelow'] == true
            @incoming_sql.where([RANK_AND_BELOW_CLAUSE, parameter])
          else
            @incoming_sql.where([CLAUSE, parameter])
          end
    @incoming_sql
  end

  def parameter
    return nil unless @parser.text_arg?(PARAMETER)
    @parser.args[PARAMETER].strip.tr('*', '%').gsub(/×/, 'x')
  end
end
