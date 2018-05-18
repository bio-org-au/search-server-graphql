# frozen_string_literal: true

Types::NameUsageType = GraphQL::ObjectType.define do
  name 'name_usage'
  field :reference_usage, Types::Name::Usages::ReferenceUsageType
  field :misapplied, types.Boolean
  field :misapplied_to_name, types.String
  field :misapplied_to_id, types.ID
  field :misapplied_by_id, types.ID
  field :misapplied_by_citation, types.String
  field :misapplied_by_reference_id, types.ID
  field :misapplied_on_page, types.String
  field :misapplication_label, types.String
  field :synonyms, types[Types::SynonymType]
  field :notes, types[Types::InstanceNoteType]
end
