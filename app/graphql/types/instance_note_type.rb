# frozen_string_literal: true

Types::InstanceNoteType = GraphQL::ObjectType.define do
  name 'instance_note'
  field :key, types.String
  field :value, types.String
end
