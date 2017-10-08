# frozen_string_literal: true

# Class that conducts taxonomy searches
class Taxonomy::Search::Base
  attr_reader :taxonomy_search_results
  # The returned object must respond to the "taxa" method call.
  def initialize(args)
    Rails.logger.debug("Taxonomy::Search::Base.new")
    @args = args
    @parser = Taxonomy::Search::Parser.new(args)
    search
  end

   # The returned object must respond to the "taxa" method call.
  def taxa
    @taxonomy_search_results
  end

  def search
    Rails.logger.debug('Taxonomy::Search::Base#search scientific_search =====')
    @taxonomy_search_results = Taxonomy::Search::Results.new
    Taxonomy::Search::SqlGenerator.new(@parser).sql.each do |result|
      @taxonomy_search_results.push Taxonomy::Search::Result.new(result)
    end
    @taxonomy_search_results
  end
end
