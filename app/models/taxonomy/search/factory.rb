# frozen_string_literal: true

# Class that builds taxonomy searches
class Taxonomy::Search::Factory
  attr_reader :taxonomy_search_results
  # The returned object must respond to the "taxa" method call.
  def self.build(args)
    Rails.logger.debug('taxonomy search factory build')
    Taxonomy::Search::Base.new(args)
  end
end
