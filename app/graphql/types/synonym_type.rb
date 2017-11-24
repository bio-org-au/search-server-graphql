# frozen_string_literal: true

Types::SynonymType = GraphQL::ObjectType.define do
  name 'synonym'
  field :id, types.ID
  field :full_name, types.String
  field :instance_type, types.String
  field :label, types.String
  field :page, types.String
  field :page_qualifier, types.String
  field :name_status_name, types.String
  field :has_type_synonym, types.Boolean
  field :of_type_synonym, types.Boolean
end
