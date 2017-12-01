# frozen_string_literal: true

# Class that builds reference searches
class Reference::Search::Factory
  attr_reader :reference_search_results
  # The returned object must respond to the "references" method call.
  def self.build(args)
    Reference::Search::Base.new(args)
  end
end
