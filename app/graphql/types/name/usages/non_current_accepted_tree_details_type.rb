# frozen_string_literal: true

# Comment and distribution may be attached to tree elements and
# need to be available even though they are not part of the current 
# tree.
Types::Name::Usages::NonCurrentAcceptedTreeDetailsType = GraphQL::ObjectType.define do
  name 'earlier_accepted_tree_details'
  field :comment, Types::InstanceNoteType
  field :distribution, Types::InstanceNoteType
end
