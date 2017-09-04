Types::NameHistoryType = GraphQL::ObjectType.define do
  name "name_history"
  field :name_usages, types[Types::NameUsageType]
end
