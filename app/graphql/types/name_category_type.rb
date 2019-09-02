# frozen_string_literal: true

Types::NameCategoryType = GraphQL::ObjectType.define do
  name 'NameCategory'
  field :id, !types.ID
  field :name, !types.String
  field :maxParentsAllowed, !types.Int, property: :max_parents_allowed
  field :minParentsRequired, !types.Int, property: :min_parents_required
  field :sortOrder, !types.Int, property: :sort_order
end
