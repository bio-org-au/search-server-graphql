# frozen_string_literal: true

# Class that conducts taxonomy searches
class Taxonomy::Search::Base
  def initialize(args)
    @args = args
    @parser = Taxonomy::Search::Parser.new(@args)
    @generator = Taxonomy::Search::SqlGeneratorFactory.new(@parser).build
  end

  # The returned object must respond to the "count" message
  def count
    @generator.count
  end

  # The returned object must respond to the "taxa" message
  def taxa
    taxonomy_search_results = Taxonomy::Search::Results.new
    @generator.search.each do |one_record|
      Rails.logger.debug(one_record.class)
      taxonomy_search_results.push one_record
    end
    taxonomy_search_results
  end
end
