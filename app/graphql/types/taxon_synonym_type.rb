# frozen_string_literal: true

Types::TaxonSynonymType = GraphQL::ObjectType.define do
  name 'taxon_synonym'
  field :id, types.ID
  field :name_id, types.ID
  field :simple_name, types.String
  field :name_status, types.String
  field :full_name, types.String
  field :full_name_html, types.String
  field :is_doubtful, types.Boolean
  field :is_misapplied, types.Boolean
  field :is_pro_parte, types.Boolean
  # field :instance_type, types.String
  # field :label, types.String
  field :page, types.String
  field :page_qualifier, types.String
  field :misapplication_details, Types::TaxonMisappliedDetailsType
end
