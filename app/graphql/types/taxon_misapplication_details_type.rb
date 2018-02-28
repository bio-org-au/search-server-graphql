# frozen_string_literal: true

Types::TaxonMisapplicationDetailsType = GraphQL::ObjectType.define do
  name 'taxon_misapplication_details'
  field :citing_instance_id, types.String
  field :citing_reference_id, types.String
  field :citing_reference_author_string_and_year, types.String
  field :misapplying_author_string_and_year, types.String
  field :pro_parte, types.Boolean
  field :name_author_string, types.String
  field :cites_simple_name, types.String
  field :cites_page, types.String
  field :cites_reference_author_string, types.String
  field :is_doubtful, types.Boolean
end
