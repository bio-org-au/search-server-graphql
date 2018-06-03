# frozen_string_literal: true

Types::Name::MisappliedInReferenceType = GraphQL::ObjectType.define do
  name 'misapplied_in_reference'
  field :id, types.ID
  field :citation, types.String
  field :page, types.String
  field :page_qualifier, types.String
  field :display_entry, types.String
end
