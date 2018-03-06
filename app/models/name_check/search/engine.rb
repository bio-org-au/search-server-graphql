# frozen_string_literal: true

# Run name check queries.
class NameCheck::Search::Engine
  include NameSearchable
  def initialize(parser)
    @parser = parser
    search
  end

  #ToDo: refactor!
  def search
    @results_array = []
    @loop_count = 0
    @limited = false
    @parser.names.each do |search_term|
      @limited = true if @loop_count >= @parser.limit
      break if @loop_count >= @parser.limit
      @per_search_term_index = 0
      sql_query = Name.name_matches(search_term)
                      .has_an_instance.joins(:name_status)
                      .where(name_status: {nom_illeg: false})
                      .where(name_status: {nom_inval: false})
      if sql_query.size > 0
        sql_query.each do |record|
          @limited = true if @loop_count >= @parser.limit
          break if @loop_count >= @parser.limit
          @loop_count += 1
          @per_search_term_index += 1
          @results_array.push(one_record(search_term, record))
        end
      else
        @results_array.push(nothing_found(search_term))
      end
    end
  end

  def results_limited
    @limited
  end

  def results
    @results_array
  end

  def results_count
    @loop_count
  end

  private

  def nothing_found(search_term)
    data = OpenStruct.new
    data.search_term = search_term
    data.found = false
    data
  end

  def one_record(search_term, record)
    Rails.logger.debug("one_record for search_term: #{search_term}")
    data = OpenStruct.new
    data.search_term = search_term
    data.found = true
    if data.found
      data.index = @per_search_term_index
      data.matched_name_id = record.id
      data.matched_name_full_name = record.full_name
      data.matched_name_family_name = record.family_name
    end
    data
  end

  def old_info(search_term, one_result)
    Rails.logger.debug("info for search_term: #{search_term}")
    data = OpenStruct.new
    data.search_term = search_term
    data.found = search.size > 0
    Rails.logger.debug("info: search.size: #{search.size}")
    if data.found
      data.matched_name_id = search.first.id
      data.matched_name_full_name = search.first.full_name
      data.matched_name_family_name = search.first.family_name
      #data.matched_name_accepted_tree_accepted, types.Boolean
    end
    data
  end
end
