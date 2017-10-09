# frozen_string_literal: true

Types::TaxonDetailsType = GraphQL::ObjectType.define do
  name 'taxon_details'
  field :instance_id, types.String
  field :taxon_synonyms, types[Types::TaxonSynonymType]
  field :taxon_distribution, types.String
  field :taxon_comment, types.String
end
