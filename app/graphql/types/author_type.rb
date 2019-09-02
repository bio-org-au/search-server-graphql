# frozen_string_literal: true

Types::AuthorType = GraphQL::ObjectType.define do
  name 'Author'
  field :id, types.ID, property: :uri
  field :fullName, types.String, property: :name
  field :standardForm, types.String, property: :abbrev
  field :ipniId, types.String, property: :ipni_id
  field :name, types.String, property: :name
  field :extraInformation, types.String, property: :full_name
end
