# frozen_string_literal: true

Types::AuthorPaginatorType = GraphQL::ObjectType.define do
  name 'authorPaginator'
  field :paginatorInfo, !Types::PaginatorInfoType, property: :paginator_info
  field :data, !types[!Types::AuthorType]
end
