# frozen_string_literal: true

Types::NameCheckResultType = GraphQL::ObjectType.define do
  name 'name_check_result'
  field :results, types[Types::NameCheckType]
  field :results_count, types.Int
  field :results_limited, types.Boolean
end
