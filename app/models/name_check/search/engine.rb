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

  # TODO: refactor!
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
                      .where(name_status: { nom_illeg: false })
                      .where(name_status: { nom_inval: false })
                      .where("name_status.name != 'isonym'")
                      .where.not(name_status: { name: 'orth. var.' })
                      .ordered_by_sort_name_and_rank
      if !sql_query.empty?
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
    debug("one_record for search_term: #{search_term}")
    data = OpenStruct.new
    data.search_term = search_term
    data.found = true
    if data.found
      debug('data found')
      data.index = @per_search_term_index
      debug('one')
      data.matched_name_id = name_record.id
      debug('two')
      data.matched_name_full_name = name_record.full_name
      debug('three')
      data.matched_name_family_name = name_record.family_name

      # 1 query
      # Name Load (1.2ms)
      # SELECT  "name".* FROM "name" WHERE "name"."id" = ? LIMIT ?
      # [["id", 54484], ["LIMIT", 1]] (pid:10248)

      debug('four')
      data.matched_name_family_name_id = name_record.family_id
      debug('five')
      # 3 queries
      data.matched_name_accepted_taxonomy_accepted = name_record.accepted?

      # CACHE (0.3ms)
      # SELECT  "tree".* FROM "tree" WHERE "tree"."accepted_tree" = ? ORDER BY "tree"."id" ASC LIMIT ?  [["accepted_tree", "t"], ["LIMIT", 1]] (pid:10248)
      #
      # search-server CACHE (0.0ms)
      # SELECT  "tree_version".* FROM "tree_version" WHERE "tree_version"."id" = ? LIMIT ?  [["id", 51316275], ["LIMIT", 1]] (pid:10248)
      #
      # TreeElement Load (5.8ms)
      # SELECT  "tree_element".*
      # FROM "tree_element" INNER JOIN
      #      "tree_version_element"
      #       ON "tree_element"."id" = "tree_version_element"."tree_element_id"
      # WHERE "tree_version_element"."tree_version_id" = ?
      #   AND "tree_element"."name_id" = ?
      # ORDER BY "tree_element"."id" ASC LIMIT ?
      # [["tree_version_id", 51316275], ["name_id", 173919], ["LIMIT", 1]] (pid:10248)

      debug('six')

      # 3 queries
      data.matched_name_accepted_taxonomy_excluded = name_record.excluded?

      # CACHE (0.1ms)
      # SELECT  "tree".*
      # FROM "tree"
      # WHERE "tree"."accepted_tree" = ?
      # ORDER BY "tree"."id" ASC LIMIT ?  [["accepted_tree", "t"], ["LIMIT", 1]]
      #
      # CACHE (0.0ms)
      # SELECT  "tree_version".*
      #   FROM "tree_version"
      #  WHERE "tree_version"."id" = ? LIMIT ?  [["id", 51316275], ["LIMIT", 1]]
      #
      # CACHE (0.0ms)
      # SELECT  "tree_element".*
      #   FROM "tree_element"
      #        INNER JOIN "tree_version_element"
      #        ON "tree_element"."id" = "tree_version_element"."tree_element_id"
      #  WHERE "tree_version_element"."tree_version_id" = ?
      #    AND "tree_element"."name_id" = ?
      #  ORDER BY "tree_element"."id" ASC LIMIT ?
      #  [["tree_version_id", 51316275],
      #  ["name_id", 173919], ["LIMIT", 1]]
      #

      debug('seven')
    end
    debug('one_record end')
    data
  end

  private

  def debug(msg)
    Rails.logger.debug("NameCheck::Search::Engine: #{msg}")
  end
end
