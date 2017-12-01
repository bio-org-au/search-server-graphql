# frozen_string_literal: true

# Rails model
# Interpret GraphQL args and provided
# directions for the required search.
class Reference::Search::Parser
  attr_reader :list_or_details,
              :limit,
              :args

  # Fuzzy or exact
  ADD_TRAILING_WILDCARD = 'add_trailing_wildcard'

  # List or list with details output
  DETAILS = 'details'
  LIST = 'list'

  # Limits
  DEFAULT_LIST_LIMIT = 1000
  DEFAULT_DETAILS_LIMIT = 3

  SIMPLE_SEARCH = 'Search'

  def initialize(args)
    Rails.logger.debug('Reference::Search::Parser.initialize')
    @args = args
  end

  def run_search?
    @args.keys.include?('publication')
  end

  def search_type
    if @args.key?(:search_type)
      "#{@args[:search_type]} Search"
    else
      SIMPLE_SEARCH
    end
  end

  def show_as
    @args[:show_results_as] || @args[:default_show_results_as] || SHOW_LIST
  end

  def limit
    if list?
      DEFAULT_LIST_LIMIT
    else
      DEFAULT_DETAILS_LIMIT
    end
  end

  def list?
    @show_as == SHOW_LIST
  end

  def show_list?
    list?
  end

  def details?
    @show_as == SHOW_DETAILS
  end

  def show_details?
    details?
  end

  def add_trailing_wildcard?
    true
  end
end
