# frozen_string_literal: true

Types::NameGroupType = GraphQL::ObjectType.define do
  name 'nameGroup'
  field :id, !types.ID
  field :name, !types.String
end

