# frozen_string_literal: true

Types::PaginatorInfoType = GraphQL::ObjectType.define do
  name 'PaginatorInfo'
  field :count, !types.Int
  field :currentPage, types.Int
  field :firstItem, types.Int
  field :hasMorePages, types.Boolean
  field :lastItem, types.Int
  field :lastPage, types.Int
  field :perPage, types.Int
  field :total, types.Int
end
