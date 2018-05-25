# frozen_string_literal: true

Types::Name::Usages::ReferenceDetailsType = GraphQL::ObjectType.define do
  name 'reference_details'
  field :id, types.ID
  field :citation, types.String
  field :citation_html, types.String
  field :page, types.String
  field :page_qualifier, types.String
  field :year, types.String
  field :full_citation_with_page, types.String
end
