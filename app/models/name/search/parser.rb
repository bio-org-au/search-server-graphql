# frozen_string_literal: true

# Rails model
# Interpret GraphQL args and provided
# directions for the required search.
class Name::Search::Parser
  attr_reader :sci_cult_or_common,
              :simple_or_advanced,
              :list_or_details,
              :args

  # Type of name
  SCIENTIFIC = 'Scientific'
  SCIENTIFIC_OR_CULTIVAR = 'Scientific-or-Cultivar'
  CULTIVAR = 'Cultivar'
  COMMON = 'Common'
  ALL = 'all'

  # Fuzzy or exact
  ADD_TRAILING_WILDCARD = 'add_trailing_wildcard'

  # List or list with details output
  DETAILS = 'details'
  LIST = 'list'

  # Limits
  DEFAULT_LIST_LIMIT = 100
  DEFAULT_DETAILS_LIMIT = 10
  MAX_LIST_LIMIT = 500
  MAX_DETAILS_LIMIT = 50

  SIMPLE_SEARCH = 'Search'

  def initialize(args)
    Rails.logger.debug('Search::Parser.initialize')
    @args = args
    #resolve_sci_cult_or_common
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
    @fuzzy_or_exact = ADD_TRAILING_WILDCARD
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
    return false unless @args.key?(:add_trailing_wildcard)
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

  def offset
    [@args[:offset].to_i, 0].max
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
    @args[:scientific_name]
  end

  def cultivar?
    @args[:cultivar_name]
  end

  def common?
    @args[:common_name]
  end

  def autonym?
    @args[:scientific_autonym_name]
  end

  def named_hybrid?
    @args[:scientific_named_hybrid_name]
  end

  def hybrid_formula?
    @args[:scientific_hybrid_formula_name]
  end

  def name_type_all?
    @sci_cult_or_common.strip.casecmp(ALL).zero?
  end

  def add_trailing_wildcard?
    @fuzzy_or_exact.casecmp(ADD_TRAILING_WILDCARD).zero?
  end

  def type_note_text
    return nil if @args[:type_note_text].blank?
    @args[:type_note_text].strip.tr('*', '%')
  end

  # Same as the arg, but remove blank elements
  def type_note_keys_without_blanks
    @args[:type_note_keys].reject(&:empty?)
  end

  def type_note_any?
    @args[:type_note_keys].nil? ||
      type_note_keys_without_blanks.blank?
  end

  def type_note_lectotype?
    return true if type_note_any?
    return true if @args[:type_note_keys].include?('lectotype')
    false
  end

  def type_note_neotype?
    return true if type_note_any?
    return true if @args[:type_note_keys].include?('neotype')
    false
  end

  def type_note_type?
    return true if type_note_any?
    return true if @args[:type_note_keys].include?('type')
    false
  end
end
