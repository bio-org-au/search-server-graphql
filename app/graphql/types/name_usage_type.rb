# frozen_string_literal: true

Types::NameUsageType = GraphQL::ObjectType.define do
  name 'name_usage'
  field :instance_id, types.ID
  field :standalone, types.Boolean
  field :instance_type_name, types.String
  field :accepted_tree_status, types.String
  field :primary_instance, types.Boolean
  field :reference_details, Types::Name::Usages::ReferenceDetailsType
  field :synonyms, types[Types::SynonymType]
  field :misapplication, types.Boolean
  field :misapplication_details, Types::Name::MisapplicationDetailsType
  field :notes, types[Types::InstanceNoteType]
end
