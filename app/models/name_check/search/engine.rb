# frozen_string_literal: true

# Run name check queries.
class NameCheck::Search::Engine
  include NameSearchable

  attr_reader :names_found_count, :results_limited,
              :names_checked_count, :results_count, :names_with_match_count
  def initialize(parser)
    @parser = parser
    search
  end

  #ToDo: refactor!
  def search
    @results_array = []
    @results_count = 0
    @names_checked_count = 0
    @names_with_match_count = 0
    @names_found_count = 0
    @results_limited = false
    @parser.names.each do |search_term|
      @results_limited = true if @results_count >= @parser.limit
      break if @results_count >= @parser.limit
      @names_checked_count += 1
      @per_search_term_index = 0
      sql_query = Name.name_matches(search_term)
                      .has_an_instance
                      .joins(:name_status)
                      .joins(:name_rank)
                      .where(name_status: {nom_illeg: false})
                      .where(name_status: {nom_inval: false})
                      .where("name_status.name != 'isonym'")
                      .where.not(name_status: {name: 'orth. var.'})
                      .ordered_scientifically
      if sql_query.size > 0
        @names_with_match_count += 1
        sql_query.each do |record|
          @results_limited = true if @results_count >= @parser.limit
          break if @results_count >= @parser.limit
          @results_count += 1
          @names_found_count += 1
          @per_search_term_index += 1
          @results_array.push(one_record(search_term, record))
        end
      else
        @results_count += 1
        @results_array.push(nothing_found(search_term))
      end
    end
  end

  def results
    @results_array
  end

  def names_to_check_count
    @parser.names.size
  end

  def names_checked_limited
    @names_checked_count < @parser.names.size
  end

  private

  def nothing_found(search_term)
    data = OpenStruct.new
    data.search_term = search_term
    data.found = false
    data
  end

  def one_record(search_term, name_record)
    Rails.logger.debug("one_record for search_term: #{search_term}")
    data = OpenStruct.new
    data.search_term = search_term
    data.found = true
    if data.found
      data.index = @per_search_term_index
      data.matched_name_id = name_record.id
      data.matched_name_full_name = name_record.full_name
      data.matched_name_family_name = name_record.family_name
      data.matched_name_family_name_id = name_record.family_id
      data.matched_name_accepted_taxonomy_accepted = name_record.accepted?
      data.matched_name_accepted_taxonomy_excluded = name_record.excluded?
    end
    data
  end
end
