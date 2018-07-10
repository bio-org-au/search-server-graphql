# frozen_string_literal: true

Types::Name::Usages::AcceptedTreeDetailsType = GraphQL::ObjectType.define do
  name 'accepted_tree_details'
  field :is_accepted, types.Boolean
  field :is_excluded, types.Boolean
  field :comment, Types::InstanceNoteType
  field :distribution, Types::InstanceNoteType
end
