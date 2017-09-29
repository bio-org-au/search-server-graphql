# frozen_string_literal: true

# Class that builds taxonomy searches
class TaxonomySearchFactory
  attr_reader :taxonomy_search_results
  # The returned object must respond to the "taxa" method call.
  def self.build(args)
    Rails.logger.debug('taxonomy search factory build')
    TaxonomySearch.new(args)
  end
end
