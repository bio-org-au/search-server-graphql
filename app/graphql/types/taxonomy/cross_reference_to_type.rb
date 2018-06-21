# frozen_string_literal: true

Types::Taxonomy::CrossReferenceToType = GraphQL::ObjectType.define do
  name 'taxon_cross_reference_to'
  field :name_id, types.String
  field :full_name, types.String
  field :full_name_html, types.String
  field :is_doubtful, types.Boolean
  field :is_pro_parte, types.Boolean
  field :is_misapplication, types.Boolean
  field :as_misapplication, Types::Taxonomy::CrossReferenceTo::AsMisapplicationType
end
