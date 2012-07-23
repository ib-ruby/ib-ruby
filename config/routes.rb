IB::Engine.routes.draw do
  # resources :bars, :module => "ib"
  resources :bars
  resources :executions
  resources :order_states
  resources :underlyings

  root :to => "underlyings#index"
end
