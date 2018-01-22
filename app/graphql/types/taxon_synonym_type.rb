# frozen_string_literal: true

Types::TaxonSynonymType = GraphQL::ObjectType.define do
  name 'taxon_synonym'
  field :id, types.ID
  field :name_id, types.ID
  field :full_name, types.String
  # field :instance_type, types.String
  # field :label, types.String
  # field :page, types.String
  # field :page_qualifier, types.String
end
