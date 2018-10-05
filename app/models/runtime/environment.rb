# frozen_string_literal: true

# Class that runs about searches
class Runtime::Environment
  def initialize(args)
    Rails.logger.debug('new env')
  end

  def value
    obj = OpenStruct.new
    obj.ruby_platform = RUBY_PLATFORM
    obj.jruby_version  = JRUBY_VERSION
    obj.ruby_version  = RUBY_VERSION
    obj.rails_version = Rails::VERSION::STRING
    obj.database = Author.find_by_sql('select current_database() as name')
                         .first
                         .name 
    obj.rails_env = Rails.env
    obj.app_version = Rails.configuration.app_version
    obj
  end
end
