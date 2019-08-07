# frozen_string_literal: true

Types::NameRankType = GraphQL::ObjectType.define do
  name 'NameRank'
  field :id, !types.ID
  field :name, !types.String
  field :hasParent, !types.Boolean, property: :parent?
  field :parentRank, Types::NameRankType, property: :parent_rank
  field :nameGroup, !Types::NameGroupType, property: :name_group
end

