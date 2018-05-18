# frozen_string_literal: true

Types::Name::Usages::ReferenceUsageType = GraphQL::ObjectType.define do
  name 'reference_usage'
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
end
