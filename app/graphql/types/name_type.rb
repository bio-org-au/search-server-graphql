# frozen_string_literal: true

Types::NameType = GraphQL::ObjectType.define do
  name 'name'
  field :id, types.ID
  field :simple_name do
    type types.String
    resolve lambda { |obj, _args, _ctx|
      obj.simple_name.gsub(/ x /, ' × ')
    }
  end
  field :full_name do
    type types.String
    resolve lambda { |obj, _args, _ctx|
      obj.full_name.gsub(/ x /, ' × ')
    }
  end
  field :full_name_html do
    type types.String
    resolve lambda { |obj, _args, _ctx|
      obj.full_name_html.gsub(/ x /, ' × ')
    }
  end
  field :name_status_name, types.String
  field :name_status_is_displayed, types.Boolean
  field :family_name, types.String
  field :name_rank_name, types.String
  field :images, Types::Name::ImagesType
  field :name_usages, types[Types::NameUsageType]
end
