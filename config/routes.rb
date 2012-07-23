IB::Engine.routes.draw do
  # resources :bars, :module => "ib"
  resources :bars
  resources :executions
  resources :underlyings

  root :to => "underlyings#index"
end
