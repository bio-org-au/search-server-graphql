# frozen_string_literal: true

# Rails model
# Interpret GraphQL args and provided
# directions for the required search.
class Taxonomy::Search::Parser
  attr_reader :search_term,
              :sci_cult_or_common,
              :simple_or_advanced,
              :list_or_details,
              :limit,
              :args

  # Type of name
  SCIENTIFIC = 'Scientific'
  SCIENTIFIC_OR_CULTIVAR = 'Scientific-or-Cultivar'
  CULTIVAR = 'Cultivar'
  COMMON = 'Common'

  # List or list with details output
  DETAILS = 'details'
  LIST = 'list'

  # Limits
  DEFAULT_LIST_LIMIT = 1000
  DEFAULT_DETAILS_LIMIT = 3

  SIMPLE_SEARCH = 'Search'

  def initialize(args)
    Rails.logger.debug('Search::Parser.initialize')
    @args = args
    resolve_sci_cult_or_common
    resolve_fuzzy_or_exact
    # @search_type = search_type
    # @search_term = search_term
    # @show_as = show_as
    # @limit = limit
  end

  def run_search?
    @args.keys.include?('search_term') ||
      @args.keys.include?('author_abbrev')
  end

  def resolve_sci_cult_or_common
    @sci_cult_or_common = SCIENTIFIC
    return unless @args.keys.include?('type_of_name')
    @sci_cult_or_common = @args['type_of_name']
  end

  def resolve_fuzzy_or_exact
    @fuzzy_or_exact = ''
    return unless @args.keys.include?('fuzzy_or_exact')
    @fuzzy_or_exact = @args['fuzzy_or_exact']
  end

  def search_type
    if @args.key?(:search_type)
      "#{@args[:search_type]} Search"
    else
      SIMPLE_SEARCH
    end
  end

  def add_trailing_wildcard
    return 'true' unless @args.key?(:add_trailing_wildcard)
    @args[:add_trailing_wildcard]
  end

  def search_term
    term = @args[:q].strip.tr('*', '%')
    return term unless add_trailing_wildcard.start_with?('t')
    term.sub(/$/, '%')
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

  def scientific?
    @sci_cult_or_common.strip.casecmp(SCIENTIFIC.downcase).zero?
  end

  def scientific_or_cultivar?
    @sci_cult_or_common.strip.casecmp(SCIENTIFIC_OR_CULTIVAR.downcase).zero?
  end

  def cultivar?
    @sci_cult_or_common.strip.casecmp(CULTIVAR.downcase).zero?
  end

  def common?
    @sci_cult_or_common.strip.casecmp(COMMON.downcase).zero?
  end

  def add_trailing_wildcard?
    false
  end
end
