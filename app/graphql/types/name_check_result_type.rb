# frozen_string_literal: true

Types::NameCheckResultType = GraphQL::ObjectType.define do
  name 'name_check_result'
  field :names_to_check_count, types.Int
  field :results, types[Types::NameCheckType]
  field :results_count, types.Int
  field :results_limited, types.Boolean
  field :names_checked_count, types.Int
  field :names_checked_limited, types.Boolean
  field :names_with_match_count, types.Int
  field :names_found_count, types.Int
end
