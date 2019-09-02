# frozen_string_literal: true

# Add a filter to the sql to answer a request.
class Name::Search::Engines::Advanced::Filters::SearchTerm
  KEY_STR = 'search_term'
  KEY_SYM = :search_term

  def initialize(incoming_sql, parser)
    debug('init')
    @incoming_sql = incoming_sql
    @parser = parser
  end

  def sql
    debug('sql')
    return @incoming_sql if parameter_value.blank?

    @incoming_sql.name_matches(parameter_value)
  end

  private

  def parameter_key
    if @parser.use_sym?
      KEY_SYM
    else
      KEY_STR
    end
  end

  def parameter_value
    debug('parameter_value')
    return nil unless @parser.text_arg?(parameter_key)

    debug('parameter_value did not return nil')
    val = @parser.args[parameter_key].strip.tr('*', '%').gsub(/×/, 'x')
    debug("val: #{val}")
    val
  end

  def debug(msg)
    Rails.logger.debug("Name::Search::Engines::Advanced::Filters::SearchTerm: #{msg}")
  end
end
