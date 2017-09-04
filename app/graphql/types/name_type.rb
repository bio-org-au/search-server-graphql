Types::NameType = GraphQL::ObjectType.define do
  name "name"
  field :id, types.ID
  field :simple_name, types.String
  field :full_name, types.String
  field :full_name_html, types.String
  field :name_status_name, types.String
  field :name_history, Types::NameHistoryType
end
