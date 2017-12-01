# frozen_string_literal: true

Types::Publication::ResponseType = GraphQL::ObjectType.define do
  name 'publication'
  field :id, types.ID
  field :citation, types.String
  field :citation_html, types.String
end
