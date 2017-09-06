Types::InstanceNoteType = GraphQL::ObjectType.define do
  name 'instance_note'
  field :id, types.ID
  field :key, types.String
  field :value, types.String
end
