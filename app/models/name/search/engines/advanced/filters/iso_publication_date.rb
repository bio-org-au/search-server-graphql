# frozen_string_literal: true

# Add a filter to the sql to answer a request.
class Name::Search::Engines::Advanced::Filters::IsoPublicationDate
  PARAMETER = 'iso_publication_date'
  PROTOLOGUE_CLAUSE = 'instance.instance_type_id in (select id from instance_type where protologue)'

  def initialize(incoming_sql, parser)
    @incoming_sql = incoming_sql
    @parser = parser
  end

  def sql
    return @incoming_sql if parameter.blank?
    @incoming_sql = @incoming_sql.joins(:instances).joins(instances: :reference).merge(Reference.where(iso_publication_date: parameter.to_i))
    @incoming_sql = @incoming_sql.where(PROTOLOGUE_CLAUSE) if @parser.args['protologue'] == '1'
    @incoming_sql
  end

  def parameter
    return nil unless @parser.text_arg?(PARAMETER)
    @parser.args[PARAMETER].strip.tr('*', '%').gsub(/×/, 'x')
  end
end
