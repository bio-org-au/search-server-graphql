# frozen_string_literal: true

Types::TaxonType = GraphQL::ObjectType.define do
  name 'taxon'
  field :id, types.ID
  field :simple_name, types.String
  field :full_name, types.String
  field :full_name_html, types.String
  field :is_excluded, types.Boolean
  field :instance_id, types.ID
  field :name_status_name, types.String
  field :name_status_is_displayed, types.Boolean
  field :reference_citation, types.String
  field :reference_id, types.ID
  field :taxon_details, Types::TaxonDetailsType
  field :cross_referenced_full_name, types.String
  field :cross_referenced_full_name_id, types.String
  field :is_misapplication, types.Boolean
  field :is_pro_parte, types.Boolean
  field :cites_instance_id, types.ID
  field :taxon_comment, types.String
  field :taxon_distribution, types.String
  field :is_cross_reference, types.Boolean
  field :cross_reference_to, Types::Taxonomy::CrossReferenceToType
  field :synonyms, types[Types::TaxonSynonymType]
  field :order_string, types.String
  field :source_object, types.String
end
