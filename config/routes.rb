Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/v1', to: 'graphql#execute'
  post '/v1', to: 'graphql#execute'
end
