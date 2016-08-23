Rails.application.routes.draw do

# Devise routes
  devise_for :users, :path => 'account'

# Users routes
  resources :users, only: [:index]

# For Static Pages (like home page)		
  get 'static_pages/home'
  get 'static_pages/help'
  get 'static_pages/contact'
  get 'static_pages/aboutus'

# Models Profile routes
  resources :profile_models

# Colors routes
  resources :colors

# Provinces routes
  resources :provinces

# Languages routes
  resources :languages

# Expertises routes
  resources :expertises

# Nationalities routes
  resources :nationalities

# Albums routes
  resources :albums do
    get 'delete'
  end

# Root
  root to: 'static_pages#home'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
