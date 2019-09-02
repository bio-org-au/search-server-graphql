# frozen_string_literal: true

# Rails model
# Interpret GraphQL args and provided
# directions for the required search.
class NameCheck::Search::Parser
  attr_reader :sci_cult_or_common,
              :args
  DEFAULT_LIMIT = 100
  def initialize(args)
    Rails.logger.debug('NameCheck::Search::Parser.initialize')
    @args = args
    Rails.logger.debug("@args: #{@args.inspect}")
    Rails.logger.debug("@args: #{@args.inspect}")
    Rails.logger.debug(%(@args["names"].size: #{@args['names'].size}))
  end

  def names
    @args['names']
  end

  def run_search?
    @args.keys.include?('search_term') ||
      @args.keys.include?('author_abbrev')
  end

  def add_trailing_wildcard
    return 'true' unless @args.key?(:add_trailing_wildcard)

    @args[:add_trailing_wildcard]
  end

  def search_term
    term = @args[:search_term].strip.tr('*', '%')
    term.sub(/$/, '%')
  end

  def limit
    @args['limit'].blank? ? DEFAULT_LIMIT : [@args['limit'].to_i, 1].max
  end

  def add_trailing_wildcard?
    false
  end
end
