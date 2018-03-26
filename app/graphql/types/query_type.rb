# frozen_string_literal: true

Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'
  description 'Root level queries.'
  # Add root-level fields here.
  # They will be entry points for queries on your schema.
  field :name_search do
    type Types::Name::SearchType
    argument :search_term, types.String
    argument :taxon_name_author_abbrev, types.String
    argument :basionym_author_abbrev, types.String
    argument :family, types.String
    argument :genus, types.String
    argument :species, types.String
    argument :rank, types.String
    argument :include_ranks_below, types.String
    argument :publication, types.String
    argument :publication_year, types.String
    argument :protologue, types.String
    argument :name_element, types.String
    argument :type_of_name, types.String
    argument :scientific_name, types.Boolean
    argument :scientific_autonym_name, types.Boolean
    argument :scientific_named_hybrid_name, types.Boolean
    argument :scientific_hybrid_formula_name, types.Boolean
    argument :cultivar_name, types.Boolean
    argument :common_name, types.Boolean
    argument :type_note_text, types.String
    argument :type_note_keys, types[types.String]
    argument :fuzzy_or_exact, types.String
    argument :order_by_name, types.Boolean
    argument :limit, types.Int
    argument :offset, types.Int
    argument :id, types.ID
    resolve ->(_obj, args, _ctx) {
      Name::Search::Factory.build(args)
    }
  end
  field :name do
    type Types::NameType
    argument :id, !types.ID
    resolve ->(_obj, args, _ctx) {
      Name.search_for_id(args['id'])
    }
  end
  field :name_check do
    type Types::NameCheckResultType
    argument :names, types[types.String]
    argument :limit, types.Int
    argument :offset, types.Int
    resolve ->(_obj, args, _ctx) {
      NameCheck::Search::Base.new(args)
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
    argument :accepted_name, types.Boolean
    argument :excluded_name, types.Boolean
    argument :cross_reference, types.Boolean
    argument :fuzzy_or_exact, types.String
    argument :limit, types.Int
    argument :offset, types.Int
    argument :id, types.ID
    resolve ->(_obj, args, _ctx) {
      Taxonomy::Search::Factory.build(args)
    }
  end
  field :publication_search do
    type Types::Publication::SearchType
    argument :publication, types.String
    argument :limit, types.Int
    resolve ->(_obj, args, _ctx) {
      Reference::Search::Factory.build(args)
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
  field :ranks do
    type Types::NameRank::OptionType
    resolve ->(_obj, args, _ctx) {
      NameRank::Search::Factory.build(args)
    }
  end
end
