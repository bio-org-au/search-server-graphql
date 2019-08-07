# frozen_string_literal: true

Types::NameStatusType = GraphQL::ObjectType.define do
  name 'nameStatus'
  field :id, !types.ID
  field :name, !types.String
  field :display, !types.Boolean, property: :display?
  field :nomIlleg, !types.Boolean, property: :nom_illeg?
  field :nomInval, !types.Boolean, property: :nom_inval?
  field :nameGroup, !Types::NameGroupType, property: :name_group
end

