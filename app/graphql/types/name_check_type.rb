# frozen_string_literal: true

Types::NameCheckType = GraphQL::ObjectType.define do
  name 'name_check'
  field :search_term, types.String
  field :index, types.ID
  field :found, types.Boolean
  field :matched_name_accepted_tree_accepted, types.Boolean
  field :matched_name_id, types.ID
  field :matched_name_full_name, types.String
  field :matched_name_family_name_id, types.ID
  field :matched_name_family_name, types.String
end
