# frozen_string_literal: true

Types::Name::SearchResultType = GraphQL::ObjectType.define do
  name 'name_search_result'
  field :names, types[Types::NameType]
  field :count, types.Int
end
