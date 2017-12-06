# frozen_string_literal: true

# Class that conducts name searches
# The instance object must respond to these methods:
# - names 
# - count
class Name::Search::Base
  def initialize(args)
    @args = args
    @parser = Name::Search::Parser.new(args)
    @generator =  Name::Search::SqlGenerator.new(@parser)
  end

  def names
    assemble_names
  end

  def count
    @generator.count
  end

  def assemble_names
    name_search_results = Name::Search::Results.new
    @generator.sql.each do |name|
      name_search_results.push name
    end
    name_search_results
  end
end
