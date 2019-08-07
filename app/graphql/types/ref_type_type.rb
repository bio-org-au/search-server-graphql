# frozen_string_literal: true

Types::RefTypeType = GraphQL::ObjectType.define do
  name 'refType'
  field :id, !types.ID
  field :name, !types.String
  field :parent, Types::RefTypeType
  field :parentOptional, !types.Boolean, property: :parent_optional?
end
