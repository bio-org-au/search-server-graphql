# frozen_string_literal: true

# Rails model
# Interpret GraphQL args and provided
# directions for the required search.
class Taxonomy::Search::Parser
  attr_reader :sci_cult_or_common,
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
  DEFAULT_LIST_LIMIT = 50
  DEFAULT_DETAILS_LIMIT = 10

  SIMPLE_SEARCH = 'Search'

  # Limits
  MAX_LIST = 500
  MAX_DETAILS = 50

  def initialize(args)
    debug('initialize')
    if args.key?('filter')
      @have_filter = true
      @args = args['filter']
      @per_page = args['count'] || 10
      @page = args['page'] || 1
    else
      @have_filter = false
      @args = args
    end
    debug("@args: #{@args.inspect}")
    resolve_sci_cult_or_common
    resolve_fuzzy_or_exact
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

  def add_trailing_wildcard
    return 'true' unless @args.key?(:add_trailing_wildcard)
    @args[:add_trailing_wildcard]
  end

  def search_term
    term = @args[:search_term].strip.tr('*', '%')
  end

  def show_as
    @args[:show_results_as] || @args[:default_show_results_as] || LIST
  end

  def xlimit
    @args['limit'].blank? ? default_limit : [@args['limit'].to_i, 1].max
  end

  def limit
    if @have_filter
      debug("@per_page: #{@per_page}")
      [(@per_page || MAX_DETAILS).try('to_i'), list? ? MAX_LIST : MAX_DETAILS ].min
    else
      [(@args.limit || MAX_DETAILS).try('to_i'), list? ? MAX_LIST : MAX_DETAILS ].min
    end
  end

  def default_limit
    list? ? DEFAULT_LIST_LIMIT : DEFAULT_DETAILS_LIMIT
  end

  def offset
    if @have_filter
      debug("@per_page: #{@per_page}")
      debug("@page: #{@page}")
      @offset = (@page - 1) * @per_page
      [@offset.to_i, 0].max
    else
      [@args[:offset].to_i, 0].max
    end
  end

  def list?
    @show_as == LIST
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

  def add_trailing_wildcard?
    false
  end

  def accepted?
    @args.key?(:accepted_name) && @args[:accepted_name] == true
  end

  def excluded?
    @args.key?(:excluded_name) && @args[:excluded_name] == true
  end

  def cross_reference?
    @args.key?(:cross_reference) && @args[:cross_reference] == true
  end

  private

  def debug(msg)
    Rails.logger.debug("Taxonomy::Search::Parser: #{msg}")
  end
end
