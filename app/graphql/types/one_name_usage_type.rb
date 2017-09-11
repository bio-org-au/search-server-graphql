# frozen_string_literal: true

Types::OneNameUsageType = GraphQL::ObjectType.define do
  name 'name_usage'
  field :name_id, types.ID
  field :author_id, types.String
  field :author_name, types.String
  field :full_name, types.String
  field :reference_citation, types.String
  field :reference_year_sort_value, types.Int
  field :reference_year, types.Int
  field :primary_instance, types.Boolean
  field :common_names_count, types.Int
end
