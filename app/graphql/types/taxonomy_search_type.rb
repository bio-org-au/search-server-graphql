# frozen_string_literal: true

Types::TaxonomySearchType = GraphQL::ObjectType.define do
  name 'taxonomy_search'
  field :taxa, types[Types::TaxonType]
end
