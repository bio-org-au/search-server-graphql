Types::NameSearchType = GraphQL::ObjectType.define do
  name "name_search"
  field :names, types[Types::NameType]
end
