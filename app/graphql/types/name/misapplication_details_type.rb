# frozen_string_literal: true

Types::Name::MisapplicationDetailsType = GraphQL::ObjectType.define do
  name 'misapplication_details'
  field :direction, types.String
  field :misapplied_to_full_name, types.String
  field :misapplied_to_name_id, types.ID
  field :misapplied_in_reference_id, types.ID
  field :misapplied_in_reference_citation, types.String
  field :misapplied_on_page, types.String
  field :misapplied_on_page_qualifier, types.String
  field :misapplication_type_label, types.String
end
