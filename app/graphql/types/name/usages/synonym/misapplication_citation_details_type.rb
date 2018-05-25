# frozen_string_literal: true

Types::Name::Usages::Synonym::MisapplicationCitationDetailsType = GraphQL::ObjectType.define do
  name 'misapplication_citation_details'
  field :misapplied_in_reference_id, types.ID
  field :misapplied_in_reference_citation, types.String
  field :misapplied_in_reference_citation_html, types.String
  field :misapplied_on_page, types.String
  field :misapplied_on_page_qualifier, types.String
  field :misapplied_in_reference_year, types.Int
  field :name_is_repeated, types.Boolean
end
