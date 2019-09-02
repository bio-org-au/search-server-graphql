# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=172800'
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end

# We need the SHARD set BEFORE config on the dev machine
# so we can run plants, mosses, lichen, etc.
#
# This does not apply in production.
#
puts "Development: ENV['SHARD']: #{ENV['SHARD']}"
ENV['SHARD'] = 'plants' if ENV['SHARD'] =~ /^test$/
ENV['SHARD'] = 'plants' if (ENV['SHARD']).nil?
puts %(Configuring shard: #{ENV['SHARD']})

begin
  raise 'no_shard_set' if (ENV['SHARD']).nil?

  puts %(Configuring shard: #{ENV['SHARD']})
rescue StandardError
  puts '=' * 100
  puts 'Expected the SHARD environmental variable to be set.'
  puts 'Application start up will now fail.'
  puts "ENV['SHARD']: #{ENV['SHARD']}"
  puts '=' * 100
  raise
end

Rails.application.config.database_yml_file_path =
  "#{ENV['HOME']}/.nsl/development/#{ENV['SHARD']}-ssg-database.yml"
puts "Rails.application.config.database_yml_file_path:
#{Rails.application.config.database_yml_file_path}"

begin
  file_path = "#{ENV['HOME']}/.nsl/development/#{ENV['SHARD']}-ssg-config.rb"
  puts "Loading config from: #{file_path}"
  load file_path
rescue LoadError
  puts '=' * 100
  puts "Unable to find the config file: #{file_path}"
  puts 'Application start up will now fail.'
  puts '=' * 100
  raise
end
