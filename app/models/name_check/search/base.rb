# frozen_string_literal: true

# Class that conducts name_check searches
class NameCheck::Search::Base
  attr_reader :parser
  def initialize(args)
    @args = args
    Rails.logger.debug(@args.inspect)
    @parser = NameCheck::Search::Parser.new(@args)
    @engine = NameCheck::Search::Engine.new(@parser)
  end

  # The returned object must respond to the "count" message
  def results_count
    @engine.results_count
  end

  # The returned object must respond to the "count" message
  def results_limited
    @engine.results_limited
  end

  # The returned object must respond to the "results" message
  def results
    @engine.results
  end
end
