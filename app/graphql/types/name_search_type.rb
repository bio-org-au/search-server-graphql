# frozen_string_literal: true

Types::NameSearchType = GraphQL::ObjectType.define do
  name 'name_search'
  field :names, types[Types::NameType]
end
