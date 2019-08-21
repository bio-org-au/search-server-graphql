# frozen_string_literal: true

Types::FilteredSearchPaginatorType = GraphQL::ObjectType.define do
  name 'FilteredSearchPaginatorType'
  field :paginatorInfo, !Types::PaginatorInfoType, property: :paginator_info
  field :data, !types[!types.String]
end
