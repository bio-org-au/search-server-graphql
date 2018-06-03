# frozen_string_literal: true

Types::Name::MisapplicationDetailsType = GraphQL::ObjectType.define do
  name 'misapplication_details'
  field :direction, types.String
  field :misapplied_to_full_name, types.String
  field :misapplied_to_name_id, types.ID
  field :misapplication_type_label, types.String
  field :misapplied_in_references, types[Types::Name::Usages::MisappliedInReferenceType]
end
