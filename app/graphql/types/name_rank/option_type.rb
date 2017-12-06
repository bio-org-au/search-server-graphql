# frozen_string_literal: true

Types::NameRank::OptionType = GraphQL::ObjectType.define do
  name 'name_rank_option'
  field :options, types[types.String]
end
