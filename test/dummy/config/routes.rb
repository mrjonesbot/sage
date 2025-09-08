Rails.application.routes.draw do
  mount Sage::Engine => "/sage"
  root "sage/home#index"
end
