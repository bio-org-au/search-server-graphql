# frozen_string_literal: true

Types::InstanceType = GraphQL::ObjectType.define do
  name 'instance'
  field :id, types.ID
  field :citation, types.String
  field :citation_html, types.String
  field :page, types.String
  field :type, types.String
end
