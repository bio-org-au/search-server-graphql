Types::QueryType = GraphQL::ObjectType.define do
  name "Query"
  description "Root level queries."
  # Add root-level fields here.
  # They will be entry points for queries on your schema.
  field :name_search do
    type Types::NameSearchType
    argument :search_term, types.String
    argument :type_of_name, types.String
    argument :fuzzy_or_exact, types.String
    argument :limit, types.Int
    argument :id, types.ID
    resolve -> (obj, args, ctx) {
      NameSearch.new(args)
    }
  end
  field :name do
    type Types::NameType
    argument :id, !types.ID
    resolve -> (obj, args, ctx) {
      Name.find(args["id"])
    }
  end
  field :reference do
    type Types::ReferenceType
    argument :id, !types.ID
    resolve -> (obj, args, ctx) {
      Reference.find(args["id"])
    }
  end
  field :name_history do
    type Types::NameHistoryType
    argument :name_id, !types.ID
    resolve -> (obj, args, ctx) {
      NameHistory.new(args["name_id"])
    }
  end
end

