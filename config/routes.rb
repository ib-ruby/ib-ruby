IB::Engine.routes.draw do
  resources :underlyings
  # resources :underlyings, :module => "ib"

  root :to => "underlyings#index"
end
