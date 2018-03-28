# frozen_string_literal: true

# Class that runs about searches
class Runtime::Environment
  def initialize(args)
  end

  def value
    "Ruby platform: #{RUBY_PLATFORM}; " + 
    "Ruby version: #{RUBY_VERSION}; " + 
    "Rails: #{Rails::VERSION::STRING}; " + 
    "Database: #{Rails.configuration.database_configuration[Rails.env]['database']}; "
  end
end
