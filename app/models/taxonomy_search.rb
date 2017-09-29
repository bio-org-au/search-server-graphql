# frozen_string_literal: true

# Class that conducts taxonomy searches
class TaxonomySearch
  attr_reader :taxonomy_search_results
  # The returned object must respond to the "taxa" method call.
  def initialize(args)
    Rails.logger.debug("TaxonomySearch.new")
    @args = args
    @parser = Search::Parser.new(args)
    search
  end

   # The returned object must respond to the "taxa" method call.
  def taxa
    @taxonomy_search_results
  end

  def search
    Rails.logger.debug('Search#search scientific_search ==================xxx')
    @taxonomy_search_results = TaxonomySearchResults.new
    TaxonomySqlGenerator.new(@parser).sql.each do |taxon|
      @taxonomy_search_results.push taxon
    end
    @taxonomy_search_results
  end
end
