# frozen_string_literal: true

Types::NamePaginatorType = GraphQL::ObjectType.define do
  name 'NamePaginator'
  field :paginatorInfo, !Types::PaginatorInfoType, property: :paginator_info
  field :data, !types[!Types::NameType]
end
