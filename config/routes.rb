Sage::Engine.routes.draw do
  get "/close_overlay", to: "actions#close_overlay", as: :close_overlay

  resources :queries, except: [ :index ] do
    post :refresh, on: :member
    get :run, on: :member

    resources :messages, only: [ :index, :create ], controller: "queries/messages"

    collection do
      post :run
      post :cancel
      get :tables
      get :schema
      get :docs
      get :table_schema
    end
  end

  resources :checks, except: [ :show ] do
    get :run, on: :member
  end

  resources :dashboards do
    member do
      post :refresh
    end
  end

  root to: "queries#index"
end
