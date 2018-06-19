# frozen_string_literal: true

Types::Taxonomy::CrossReferenceTo::AsMisapplicationType = GraphQL::ObjectType.define do
  name 'as_misapplication'
  field :citing_instance_id, types.String
  field :citing_reference_id, types.String
  field :citing_reference_author_string_and_year, types.String
  field :misapplying_author_string_and_year, types.String
  field :name_author_string, types.String
  field :cited_simple_name, types.String
  field :cited_page, types.String
  field :cited_reference_author_string, types.String
end
