# frozen_string_literal: true

Types::Name::SearchType = GraphQL::ObjectType.define do
  name 'name_search'
  field :names, types[Types::NameType]
end
