# frozen_string_literal: true

Types::RefAuthorRoleType = GraphQL::ObjectType.define do
  name 'RefAuthorRoleType'
  field :id, !types.ID
  field :name, !types.String
end
