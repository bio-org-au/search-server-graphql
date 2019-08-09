# frozen_string_literal: true

Types::TaxonomicNameUsagePaginatorType = GraphQL::ObjectType.define do
  name 'TaxonomicNameUsagePaginator'
  field :paginatorInfo, !Types::PaginatorInfoType, property: :paginator_info
  field :data, !types[!Types::TaxonomicNameUsageType]
end
