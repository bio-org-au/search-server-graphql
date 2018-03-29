# frozen_string_literal: true

Types::Runtime::EnvironmentType = GraphQL::ObjectType.define do
  name 'runtime_environment'
  field :ruby_platform, types.String
  field :ruby_version, types.String
  field :rails_version, types.String
  field :database, types.String
end
