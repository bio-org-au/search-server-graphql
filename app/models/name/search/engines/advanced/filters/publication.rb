# frozen_string_literal: true

# Add a filter to the sql to answer a request.
class Name::Search::Engines::Advanced::Filters::Publication
  PARAMETER = 'publication'
  PROTOLOGUE_CLAUSE = 'instance.instance_type_id in (select id from instance_type where protologue)'

  def initialize(incoming_sql, parser)
    @incoming_sql = incoming_sql
    @parser = parser
  end

  # Originally tried
  # .merge(Reference.search_citation_text_for(parameter))
  # which uses the pg_search gem
  # but this imposed a ranked order by clause on the selectcw
  # which conflicted with our requirement.
  # Search also seemed much faster after removing the merge.
  def sql
    return @incoming_sql if parameter.blank?
    @incoming_sql = @incoming_sql.joins(:instances)
                                 .joins(instances: :reference)
                                 .where([text_search_version,
                                         text_search_param(parameter)])
    @incoming_sql = @incoming_sql.where(PROTOLOGUE_CLAUSE) if @parser.args['protologue'] == true
    @incoming_sql
  end

  def parameter
    return nil unless @parser.text_arg?(PARAMETER)
    @parser.args[PARAMETER].strip.tr('*', '%').gsub(/×/, 'x')
  end

  def text_search_version
    "to_tsvector('english'::regconfig, f_unaccent(COALESCE(citation::text, ''::text))) @@ plainto_tsquery(f_unaccent(?))"
  end

  def text_search_param(parameter)
    parameter.gsub(/[%*]/,'')
  end

  # For possible alternative use
  def wildcard_search_version
    "lower(reference.citation) like ?"
  end

  # For possible alternative use
  def wildcard_search_param(parameter)
    parameter.downcase
  end
end
