Types::ReferenceType = GraphQL::ObjectType.define do
  name "reference"
  field :id, types.ID
  field :citation, types.String
end
