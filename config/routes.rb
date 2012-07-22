IB::Engine.routes.draw do
  # resources :bars, :module => "ib"
  resources :bars
  resources :underlyings

  root :to => "underlyings#index"
end
