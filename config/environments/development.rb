Rails.application.configure do
  # Settings specified here will take precedence over those in
  # config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all
  # assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end


# We need the SHARD set BEFORE config on the dev machine
# so we can run plants, mosses, lichen, etc.
#
# This does not apply in production.
#
puts "Development: ENV['SHARD']: #{ENV['SHARD']}"
ENV["SHARD"] = "plants" if ENV["SHARD"] =~ /^test$/
ENV["SHARD"] = "plants" if (ENV["SHARD"]).nil?
puts %(Configuring shard: #{ENV['SHARD']})

begin
  raise "no_shard_set" if (ENV["SHARD"]).nil?
  puts %(Configuring shard: #{ENV['SHARD']})
rescue
  puts "=" * 100
  puts "Expected the SHARD environmental variable to be set."
  puts "Application start up will now fail."
  puts "ENV['SHARD']: #{ENV['SHARD']}"
  puts "=" * 100
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
  puts "=" * 100
  puts "Unable to find the config file: #{file_path}"
  puts "Application start up will now fail."
  puts "=" * 100
  raise
end
