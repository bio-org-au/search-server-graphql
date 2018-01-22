# frozen_string_literal: true

source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.10'
# Use jdbcpostgresql as the database for Active Record
platform :jruby do
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'jruby-jars', '9.1.12.0'
  gem 'warbler'
end

platform :ruby do
  gem 'pg'
end
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyrhino'
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'graphql'
gem 'pg_search'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'graphiql-rails', group: :development

group :development do
  gem 'awesome_print'
  gem 'puma'
  # gem "better_errors", "~>1.0"
  # gem "spring"
  # gem "binding_of_caller", platforms: [:mri_19, :mri_20, :mri_21, :rbx]
  # gem "guard-bundler"
  # gem "guard-rails"
  # gem "guard-test"
  # gem "quiet_assets"
  # gem "rails_layout"
  # gem "rb-fchange", require: false
  # gem "rb-fsevent", require: false
  # gem "rb-inotify", require: false
  # gem "rails-erd"
end

group :development, :test do
  gem 'pry-rails'
  gem 'pry-rescue'
  # gem "webmock"
  # gem "schema_plus"
end
