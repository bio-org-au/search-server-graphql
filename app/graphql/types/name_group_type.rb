# frozen_string_literal: true

Types::NameGroupType = GraphQL::ObjectType.define do
  name 'NameGroup'
  field :id, !types.ID
  field :name, !types.String
end

