# frozen_string_literal: true

Types::TaxonomicNamePaginatorType = GraphQL::ObjectType.define do
  name 'TaxonomicNamePaginator'
  field :paginatorInfo, !Types::PaginatorInfoType, property: :paginator_info
  field :data, !types[!Types::TaxonomicNameType]
end
