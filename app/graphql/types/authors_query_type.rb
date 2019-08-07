# frozen_string_literal: true

Types::AuthorsQueryType = GraphQL::ObjectType.define do
  name 'authors'
  field :authors, types[Types::AuthorType]
end
