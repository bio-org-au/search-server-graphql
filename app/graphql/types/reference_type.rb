# frozen_string_literal: true

Types::ReferenceType = GraphQL::ObjectType.define do
  name 'reference'
  field :id, types.ID
  field :citation, types.String
end
