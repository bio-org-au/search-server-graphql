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

  # List or list with details output
  DETAILS = 'details'
  LIST = 'list'

  # Limits
  MAX_LIST = 500
  MAX_DETAILS = 50

  SIMPLE_SEARCH = 'Search'

  def initialize(args)
    debug('Search::Parser.initialize')
    if args.key?('filter')
      @have_filter = true
      @args = args['filter']
      @per_page = args['count'] || 10
      @page = args['page'] || 1
    else
      @have_filter = false
      @args = args
    end
    resolve_sci_cult_or_common
  end

  def use_sym?
    @have_filter
  end

  def run_search?
    @args.keys.include?('search_term') ||
      author_arg?
  end

  # The @args object keys method returns the underscore versions of the keys,
  # but @args itself provides a value for the camel_case version of the key.
  def text_arg?(camel_case_arg_name_sym)
    underscore_arg_name = camel_case_arg_name_sym.to_s.underscore.to_sym
    @args.keys.include?(underscore_arg_name.to_sym) && !@args[camel_case_arg_name_sym].blank?
  end

  def search_term_arg?
    throw 'search_term_arg'
    # @args.keys.include?('search_term') && !@args['search_term'].strip.blank?
    'angophora'
  end

  def resolve_sci_cult_or_common
    @sci_cult_or_common = SCIENTIFIC
    return unless @args.keys.include?('type_of_name')

    @sci_cult_or_common = @args['type_of_name']
  end

  def simple?
    false
  end

  def search_type
    if @args.key?(:search_type)
      "#{@args[:search_type]} Search"
    else
      SIMPLE_SEARCH
    end
  end

  def search_term
    throw('search_term')
    # term = @args.search_term.strip.tr('*', '%')
    @args['filter']['search_term'].strip.tr('*', '%')
  end

  def show_as
    @args[:show_results_as] || @args[:default_show_results_as] || LIST
  end

  def limit
    if @have_filter
      [(@per_page || MAX_DETAILS).try('to_i'), list? ? MAX_LIST : MAX_DETAILS].min
    else
      [(@args.limit || MAX_DETAILS).try('to_i'), list? ? MAX_LIST : MAX_DETAILS].min
    end
  end

  def offset
    if @have_filter
      @offset = (@page - 1) * @per_page
      [@offset.to_i, 0].max
    else
      [@args[:offset].to_i, 0].max
    end
  end

  def list?
    show_as == LIST
  end

  def show_list?
    list?
  end

  def details?
    show_as == DETAILS
  end

  def show_details?
    details?
  end

  def merge?
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

  def family_order?
    order_by_name_within_family?
  end

  def order_by_name_within_family?
    @args[:order_by_name_within_family] == true
  end

  def order_by_name?
    @args[:order_by_name] == true || common?
  end

  def order_scientifically?
    !order_by_name?
  end
  
  def protologue?
    @args[:protologue]
  end

  private

  def debug(msg)
    # Rails.logger.debug("Name::Search::Parser: #{msg}")
  end
end
