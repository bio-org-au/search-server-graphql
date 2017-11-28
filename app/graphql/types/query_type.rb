# frozen_string_literal: true

Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'
  description 'Root level queries.'
  # Add root-level fields here.
  # They will be entry points for queries on your schema.
  field :name_search do
    type Types::Name::SearchType
    argument :search_term, types.String
    argument :author_abbrev, types.String
    argument :family, types.String
    argument :genus, types.String
    argument :species, types.String
    argument :rank, types.String
    argument :publication, types.String
    argument :type_of_name, types.String
    argument :fuzzy_or_exact, types.String
    argument :limit, types.Int
    argument :id, types.ID
    resolve ->(_obj, args, _ctx) {
      Name::Search::Factory.build(args)
    }
  end
  field :name do
    type Types::NameType
    argument :id, !types.ID
    resolve ->(_obj, args, _ctx) {
      Name.find(args['id'])
    }
  end
  field :reference do
    type Types::ReferenceType
    argument :id, !types.ID
    resolve ->(_obj, args, _ctx) {
      Reference.find(args['id'])
    }
  end
  field :name_history do
    type Types::NameHistoryType
    argument :name_id, !types.ID
    resolve ->(_obj, args, _ctx) {
      NameHistory.new(args['name_id'])
    }
  end
  field :taxonomy_search do
    type Types::Taxonomy::SearchType
    argument :search_term, types.String
    argument :author_abbrev, types.String
    argument :type_of_name, types.String
    argument :fuzzy_or_exact, types.String
    argument :limit, types.Int
    argument :id, types.ID
    resolve ->(_obj, args, _ctx) {
      Taxonomy::Search::Factory.build(args)
    }
  end
  # using settings instead of config to avoid name
  # collisions with rails (I presume)
  field :setting do
    type types.String
    argument :search_term, types.String
    resolve ->(_obj, args, _ctx) {
      Settings::Search.new(args).value
    }
  end
end
