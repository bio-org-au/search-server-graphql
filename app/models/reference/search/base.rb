# frozen_string_literal: true

# Class that conducts reference searches
# The instance object must respond to these methods:
# - references
# - count
class Reference::Search::Base
  attr_reader :reference_search_results
  def initialize(args)
    @args = args
    @parser = Reference::Search::Parser.new(args)
    @generator = Reference::Search::SqlGenerator.new(@parser)
    assemble_references
  end

  def publications
    @reference_search_results
  end

  def count
    @generator.count
  end

  def assemble_references
    @reference_search_results = Reference::Search::Results.new
    @generator.sql.each do |reference|
      @reference_search_results.push reference
    end
  end
end
