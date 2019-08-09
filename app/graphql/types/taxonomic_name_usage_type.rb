# frozen_string_literal: true

Types::TaxonomicNameUsageType = GraphQL::ObjectType.define do
  name 'TaxonomicNameUsage'
  field :id, types.ID
  field :taxonomicName, Types::TaxonomicNameType, property: :name
  field :accordingTo, Types::ReferenceTypeForNewSchema, property: :reference
  field :microReference, types.String, property: :page
  field :verbatimNameString, types.String, property: :verbatim_name_string
  field :taxonomicNameUsageLabel, types.String, property: :taxonomic_name_usage_label
  field :notes, types[Types::TaxonomicNameUsageNoteType], property: :instance_notes
  field :parent, Types::TaxonomicNameUsageType
  field :children, types[Types::TaxonomicNameUsageType]
end
