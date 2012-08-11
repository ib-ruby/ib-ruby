IB::Engine.routes.draw do
  # resources :bars, :module => "ib"
  resources :bars
  resources :combo_legs
  resources :contracts
  resources :contract_details
  resources :executions
  resources :orders
  resources :order_states
  resources :underlyings

  root :to => "underlyings#index"
end
