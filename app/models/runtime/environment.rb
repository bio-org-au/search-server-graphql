# frozen_string_literal: true

# Class that runs about searches
class Runtime::Environment
  def initialize(args)
    Rails.logger.debug('new env')
  end

  def value
    obj = OpenStruct.new
    obj.ruby_platform = RUBY_PLATFORM
    obj.ruby_version  = RUBY_VERSION
    obj.rails_version = Rails::VERSION::STRING
    obj.database = Rails.configuration.database_configuration[Rails.env]['database']
    obj
  end
end
