# frozen_string_literal: true

Types::FilteredNamesPaginatorType = GraphQL::ObjectType.define do
  name 'FilteredNamesPaginatorType'
  field :paginatorInfo, !Types::PaginatorInfoType, property: :paginator_info
  field :data, !types[!Types::NameType]
end
