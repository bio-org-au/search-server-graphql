# frozen_string_literal: true

Types::TaxonType = GraphQL::ObjectType.define do
  name 'taxon'
  field :record_type, types.String
  field :id, types.ID
  field :instance_id, types.ID
  field :simple_name, types.String
  field :full_name, types.String
  field :full_name_html, types.String
  field :name_status_name, types.String
  field :reference_citation, types.String
  field :reference_id, types.ID
  field :taxon_details, Types::TaxonDetailsType
  field :cross_referenced_full_name, types.String
  field :is_misapplication, types.Boolean
  field :is_pro_parte, types.Boolean
  field :cites_instance_id, types.ID
  field :accepted_taxon_comment, types.String
  field :accepted_taxon_distribution, types.String
  field :synonyms, types[Types::TaxonSynonymType]
  field :cross_reference_misapplication_details, Types::TaxonMisapplicationDetailsType
  field :order_string, types.String
  field :source_object, types.String
end
