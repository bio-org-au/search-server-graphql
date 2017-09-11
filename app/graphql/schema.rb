# frozen_string_literal: true

Schema = GraphQL::Schema.define do
  # The line:
  #    mutation(Types::MutationType)
  # causes an error in the GraphiQL console:
  #
  # "Error: Mutation fields must be an object with field names as keys or a
  # function which returns such an object."
  #
  # See https://github.com/howtographql/howtographql/issues/150
  # "This is due to rails generate graphql:install generating a schema
  #  that includes the mutation type, but at this point in the tutorial
  #  it is still empty."
  #
  # Hence I have commented out this line:
  # mutation(Types::MutationType)
  query(Types::QueryType)
end
