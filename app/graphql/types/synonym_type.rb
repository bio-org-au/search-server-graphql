Types::SynonymType = GraphQL::ObjectType.define do
  name "synonym"
  field :id, types.ID
  field :full_name, types.String
  field :instance_type, types.String
  field :label, types.String
  field :page, types.String
  field :page_qualifier, types.String
end
