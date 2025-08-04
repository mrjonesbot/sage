Sage::Engine.routes.draw do
  root to: "queries#new"
  
  resources :queries, only: [:new, :create] do
    member do
      post :run
    end
  end
end
