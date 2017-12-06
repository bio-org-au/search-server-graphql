# frozen_string_literal: true

# Class that builds name_rank searches
class NameRank::Search::Factory
  attr_reader :options
  # The returned object must respond to the "options" method call.
  def self.build(args)
    NameRank::Search::Base.new
  end
end
