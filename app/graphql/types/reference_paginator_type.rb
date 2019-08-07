# frozen_string_literal: true

Types::ReferencePaginatorType = GraphQL::ObjectType.define do
  name 'ReferencePaginator'
  field :paginatorInfo, !Types::PaginatorInfoType, property: :paginator_info
  field :data, !types[!Types::ReferenceTypeForNewSchema]
end
