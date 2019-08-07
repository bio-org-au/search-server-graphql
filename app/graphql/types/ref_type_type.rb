# frozen_string_literal: true

Types::RefTypeType = GraphQL::ObjectType.define do
  name 'RefType'
  field :id, !types.ID
  field :name, !types.String
  field :parent, Types::RefTypeType
  field :parentOptional, !types.Boolean, property: :parent_optional?
  field :useParentDetails, !types.Boolean, property: :use_parent_details?
end
