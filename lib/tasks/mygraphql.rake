# frozen_string_literal: true

namespace :mygraphql do
  desc 'Dumps the Graphql schema to app/graphql/schema.graphql'
  # See https://rmosolgo.github.io/blog/2017/03/16/tracking-schema-changes-with-graphql-ruby/
  task dump_schema: :environment do
    # Get a string containing the definition in GraphQL IDL:
    schema_defn = Schema.to_definition
    # Choose a place to write the schema dump:
    schema_path = 'app/graphql/schema.graphql'
    # Write the schema dump to that file:
    File.write(Rails.root.join(schema_path), schema_defn)
    puts "Updated #{schema_path}"
  end
end
