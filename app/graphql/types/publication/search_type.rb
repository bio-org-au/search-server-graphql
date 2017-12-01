# frozen_string_literal: true

Types::Publication::SearchType = GraphQL::ObjectType.define do
  name 'publication_search'
  field :publications, types[Types::Publication::ResponseType]
  field :count, types.Int
end
