Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/v1', to: 'graphql#execute'
  post '/v1', to: 'graphql#execute'
  match '/home', as: 'home', to: 'admin#home', via: :get
  match '/settings', as: 'settings', to: 'admin#settings', via: :get
  match '/changes', as: 'changes', to: 'admin#changes', via: :get
  root to: 'admin#home'
end
