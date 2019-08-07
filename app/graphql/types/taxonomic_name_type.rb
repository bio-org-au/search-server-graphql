# frozen_string_literal: true

Types::TaxonomicNameType = GraphQL::ObjectType.define do
  name 'taxonomic_name'
  field :id, !types.ID, property: :uri
  # "Name string without authors" - Niels schema
  field :fullName, types.String, property: :simple_name
  field :genericName, types.String, property: :generic_name
  field :infragenericEpithet, types.String, property: :infrageneric_epithet
  field :specificEpithet, types.String, property: :name_element
  field :infraspecificEpithet, types.String, property: :infraspecific_epithet
  field :cultivarEpithet, types.String, property: :cultivar_epithet
  field :authorship, types.String, property: :authorship
  field :fullNameWithAuthorship, types.String, property: :full_name
  field :author, Types::AuthorType, property: :author
  field :exAuthor, Types::AuthorType, property: :ex_author
  field :basionymAuthor, Types::AuthorType, property: :base_author
  field :basionymExAuthor, Types::AuthorType, property: :ex_base_author
  #field :namePublishedIn, Reference, property: :primary_reference
  field :namePublishedIn, types.String, property: :primary_reference
  field :publishedYear, types.Int, property: :published_year  # name.published_year values are all null
  field :rank, !Types::NameRankType, property: :name_rank
  field :verbatimRank, types.String, property: :verbatim_rank
  field :nomenclaturalCode, types.String, property: :name_type_name_group_name
  ## Status under the nomenclatural code that applies to the group of organisms
  ## being named.
  #field :nomenclaturalStatus, NameStatus!
  field :nomenclaturalStatus, types.String, property: :name_status_record
  ## List of all Taxonomic Name Usages with this Taxonomic Name
  # field :taxonomicNameUsages, [TaxonomicNameUsage!]
  # field :basionym, TaxonomicName
  # field :otherCombinations, [TaxonomicName]
end
