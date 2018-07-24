# frozen_string_literal: true

Types::Name::ImagesType = GraphQL::ObjectType.define do
  name 'name_images'
  field :count, types.Int
  field :link, types.String
end
