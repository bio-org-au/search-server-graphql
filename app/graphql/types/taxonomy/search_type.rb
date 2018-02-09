# frozen_string_literal: true

Types::Taxonomy::SearchType = GraphQL::ObjectType.define do
  name 'taxonomy_search'
  field :taxa, types[Types::TaxonType]
  field :count, types.Int
end
