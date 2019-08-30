# frozen_string_literal: true

Types::FilteredTaxonomyPaginatorType = GraphQL::ObjectType.define do
  name 'FilteredTaxonomyPaginatorType'
  field :paginatorInfo, !Types::PaginatorInfoType, property: :paginator_info
  field :data, !types[!Types::TaxonType]
end
