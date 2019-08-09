# frozen_string_literal: true

Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'
  description 'Root level queries.'
  # Add root-level fields here.
  # They will be entry points for queries on your schema.
  field :name_search do
    type Types::Name::SearchResultType
    argument :search_term, types.String
    argument :author_abbrev, types.String
    argument :ex_author_abbrev, types.String
    argument :base_author_abbrev, types.String
    argument :ex_base_author_abbrev, types.String
    argument :family, types.String
    argument :genus, types.String
    argument :species, types.String
    argument :rank, types.String
    argument :include_ranks_below, types.Boolean
    argument :publication, types.String
    argument :iso_publication_date, types.String
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
    argument :order_by_name, types.Boolean
    argument :order_by_name_within_family, types.Boolean
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
      Taxonomy::Search::Base.new(args)
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
  field :runtime_environment do
    type Types::Runtime::EnvironmentType
    resolve ->(_obj, args, _ctx) {
      Runtime::Environment.new(args).value
    }
  end
  field :author do
    type Types::AuthorType
    argument :id, types.String
    resolve ->(_obj, args, _ctx) {
      Author::Find.new(args)
    }
  end
  field :authors do
    argument :count, types.Int
    argument :page, types.Int
    argument :size, types.Int
    type Types::AuthorPaginatorType
    resolve ->(_obj, args, _ctx) {
      Authors::Find.new(args)
    }
  end
  field :taxonomicName do
    type Types::TaxonomicNameType
    argument :id, types.String
    resolve ->(_obj, args, _ctx) {
      TaxonomicName::Find.new(args)
    }
  end
  field :nameRank do
    type Types::NameRankType
    argument :id, types.Int
    resolve ->(_obj, args, _ctx) {
      NameRank::Find.new(args)
    }
  end
  field :nameGroup do
    type Types::NameGroupType
    argument :id, types.Int
    resolve ->(_obj, args, _ctx) {
      NameGroup::Find.new(args)
    }
  end
  field :nameStatus do
    type Types::NameStatusType
    argument :id, types.Int
    resolve ->(_obj, args, _ctx) {
      NameStatus::Find.new(args)
    }
  end
  field :nameType do
    type Types::NameTypeType
    argument :id, types.Int
    resolve ->(_obj, args, _ctx) {
      NameType::Find.new(args)
    }
  end
  field :nameCategory do
    type Types::NameCategoryType
    argument :id, !types.Int
    resolve ->(_obj, args, _ctx) {
      NameCategory::Find.new(args)
    }
  end
  field :reference do
    type Types::ReferenceTypeForNewSchema
    argument :id, !types.Int
    resolve ->(_obj, args, _ctx) {
      Reference::Find.new(args)
    }
  end
  field :refType do
    type Types::RefTypeType
    argument :id, !types.Int
    resolve ->(_obj, args, _ctx) {
      RefType::Find.new(args)
    }
  end
  field :refAuthorRole do
    type Types::RefAuthorRoleType
    argument :id, !types.Int
    resolve ->(_obj, args, _ctx) {
      RefAuthorRole::Find.new(args)
    }
  end
  field :references do
    argument :count, types.Int
    argument :page, types.Int
    argument :size, types.Int
    type Types::ReferencePaginatorType
    resolve ->(_obj, args, _ctx) {
      References::Find.new(args)
    }
  end
  field :taxonomicNameUsage do
    argument :id, types.ID
    type Types::TaxonomicNameUsageType
    resolve ->(_obj, args, _ctx) {
      TaxonomicNameUsage::Find.new(args)
    }
  end
  field :taxonomicNameUsageNote do
    argument :id, types.ID
    type Types::TaxonomicNameUsageNoteType
    resolve ->(_obj, args, _ctx) {
      TaxonomicNameUsageNote::Find.new(args)
    }
  end
  field :taxonomicNameUsages do
    argument :filter, Types::TaxonomicNameUsageFilterType
    type Types::TaxonomicNameUsagePaginatorType
    resolve ->(_obj, args, _ctx) {
      TaxonomicNameUsages::Find.new(args)
    }
  end
end
