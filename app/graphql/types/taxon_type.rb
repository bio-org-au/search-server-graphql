# frozen_string_literal: true

Types::TaxonType = GraphQL::ObjectType.define do
  name 'taxon'
  field :record_type, types.String
  field :id, types.ID
  field :simple_name, types.String
  field :full_name, types.String
  field :full_name_html, types.String
  field :name_status_name, types.String
  field :reference_citation, types.String
  field :taxon_details, Types::TaxonDetailsType
  field :cross_referenced_full_name, types.String
  field :cites_misapplied, types.Boolean
  field :accepted_taxon_comment, types.String
  field :accepted_taxon_distribution, types.String
end
