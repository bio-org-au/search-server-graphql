# frozen_string_literal: true

# Class that builds name searches
class Name::Search::Factory
  attr_reader :name_search_results
  # The returned object must respond to the "names" method call.
  def self.build(args)
    Rails.logger.debug('Name::Search::Factory build')
    Name::Search::Base.new(args)
  end
end
