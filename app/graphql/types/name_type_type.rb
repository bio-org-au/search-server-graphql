# frozen_string_literal: true

# Created while working on Niels schema.
# Need to reconcile with name_type.rb - whose name doesn't fit the pattern
Types::NameTypeType = GraphQL::ObjectType.define do
  name 'NameType'
  field :id, !types.ID
  field :name, !types.String
  field :cultivar, !types.Boolean, property: :cultivar?
  field :formula, !types.Boolean, property: :formula?
  field :hybrid, !types.Boolean, property: :hybrid?
  field :scientific, !types.Boolean, property: :scientific?
  field :nameGroup, !Types::NameGroupType, property: :name_group
end
