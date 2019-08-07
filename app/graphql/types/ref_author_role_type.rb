# frozen_string_literal: true

Types::RefAuthorRoleType = GraphQL::ObjectType.define do
  name 'refAuthorRoleType'
  field :id, !types.ID
  field :name, !types.String
end
