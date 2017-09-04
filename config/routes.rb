Rails.application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
  get "/v1", to: "graphql#execute"
  post "/v1", to: "graphql#execute"
  # post "/graphql", to: "graphql#execute"
end
