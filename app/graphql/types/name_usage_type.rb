# frozen_string_literal: true

Types::NameUsageType = GraphQL::ObjectType.define do
  name 'name_usage'
  field :instance_id, types.ID
  field :name_id, types.ID
  field :reference_id, types.ID
  field :citation, types.String
  field :page, types.String
  field :page_qualifier, types.String
  field :year, types.String
  field :standalone, types.Boolean
  field :instance_type_name, types.String
  field :accepted_tree_status, types.String
  field :primary_instance, types.Boolean
  field :misapplied, types.Boolean
  field :misapplied_to_name, types.String
  field :misapplied_to_id, types.ID
  field :misapplied_by_id, types.ID
  field :misapplied_by_citation, types.String
  field :misapplied_on_page, types.String
  field :misapplication_label, types.String
  field :synonyms, types[Types::SynonymType]
  field :notes, types[Types::InstanceNoteType]
end
