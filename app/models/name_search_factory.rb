# frozen_string_literal: true

# Class that builds name searches
class NameSearchFactory
  attr_reader :name_search_results
  # The returned object must respond to the "names" method call.
  def self.build(args)
    Rails.logger.debug('name search factory build')
    NameSearch.new(args)
  end
end
