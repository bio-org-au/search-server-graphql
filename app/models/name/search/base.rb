# frozen_string_literal: true

# Class that conducts name searches
class Name::Search::Base
  attr_reader :name_search_results
  # The returned object must respond to the "names" method call.
  def initialize(args)
    Rails.logger.debug("Name::Search::Base.new")
    @args = args
    @parser = Name::Search::Parser.new(args)
    search
  end

  # The returned object must respond to the "names" method call.
  def names
    @name_search_results
  end

  def search
    Rails.logger.debug('Name::Search::Base#search scientific_search ==================xxx')
    @name_search_results = Name::Search::Results.new
    Name::Search::SqlGenerator.new(@parser).sql.each do |name|
      @name_search_results.push name
    end
    @name_search_results
  end
end
