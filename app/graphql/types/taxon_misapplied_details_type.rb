# frozen_string_literal: true

Types::TaxonMisappliedDetailsType = GraphQL::ObjectType.define do
  name 'taxon_misapplied_details'
  field :name_author_string, types.String
  field :cites_simple_name, types.String
  field :page, types.String
  field :cites_reference_citation, types.String
  field :cites_reference_citation_html, types.String
  field :cites_reference_author_string, types.String
end
