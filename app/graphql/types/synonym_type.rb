# frozen_string_literal: true

Types::SynonymType = GraphQL::ObjectType.define do
  name 'synonym'
  field :id, types.ID
  field :name_id, types.ID
  field :full_name, types.String
  field :full_name_html, types.String
  field :instance_type, types.String
  field :label, types.String
  field :page, types.String
  field :page_qualifier, types.String
  field :name_status_name, types.String
  field :has_type_synonym, types.Boolean
  field :of_type_synonym, types.Boolean
  field :reference_citation, types.String
  field :reference_page, types.String
  field :year, types.Int
  field :misapplied, types.Boolean
  field :misapplication_citation_details, Types::Name::Usages::Synonym::MisapplicationCitationDetailsType
end
