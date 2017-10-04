# frozen_string_literal: true

Types::TaxonType = GraphQL::ObjectType.define do
  name 'taxon'
  field :id, types.ID
  field :simple_name, types.String
  field :full_name, types.String
  field :full_name_html, types.String
  field :name_status_name, types.String
  field :reference_citation, types.String
  field :synonyms, Types::SynonymType
end
