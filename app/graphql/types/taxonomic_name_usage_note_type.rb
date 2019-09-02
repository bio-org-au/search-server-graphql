# frozen_string_literal: true

Types::TaxonomicNameUsageNoteType = GraphQL::ObjectType.define do
  name 'TaxonomicNameUsageNote'
  field :id, types.ID
  field :kindOfNote, types.String, property: :key
  field :value, types.String
end
