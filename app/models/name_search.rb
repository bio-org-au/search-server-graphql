# frozen_string_literal: true

# Class that conducts name searches
class NameSearch
  attr_reader :name_search_results
  # The returned object must respond to the "names" method call.
  def initialize(args)
    Rails.logger.debug("NameSearch.new")
    @args = args
    @parser = Search::Parser.new(args)
    search
  end

  # The returned object must respond to the "names" method call.
  def names
    @name_search_results
  end

  def search
    Rails.logger.debug('Search#search scientific_search ==================xxx')
    @name_search_results = NameSearchResults.new
    SqlGenerator.new(@parser).sql.each do |name|
      Rails.logger.debug("name: #{name.inspect}")
      @name_search_results.push name
    end
    @name_search_results
  end
end
