Rails.application.routes.draw do

  resources :categories
  resources :ethnicities
# For internationalization
  get '/change_locale/:locale', to: 'settings#change_locale', as: :change_locale

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
  resources :profile_models do
    get 'show_resume', on: :member
    get 'show_for_review', on: :member
    get 'show_professional_photos', on: :member
    get 'show_polaroid_photos', on: :member
    get 'show_selected_photo/:photo_id', to: 'profile_models#show_selected_photo', as: :selected_photo, on: :member
    get 'publish', on: :member
    get 'no_publish', on: :member
  end

# Photographers Profile routes
  resources :profile_photographers do
    get 'show_resume', on: :member
  end

# Models Profile routes
  resources :profile_contractors

# Colors routes
  resources :colors

# Provinces routes
  resources :provinces

# Languages routes
  resources :languages

# Expertises routes
  resources :expertises

# Modalities routes
  resources :modalities

# Nationalities routes
  resources :nationalities

# Photos concern
  concern :attachable do
    resources :photos do
      get 'uploaded', on: :member
    end
  end 

# Albums routes
  resources :albums do
    concerns :attachable
    get 'delete', on: :member
  end

# Studies routes
  resources :studies

# Messages routes
  resources :messages do
    get '/read_all/', to: 'messages#read_all', as: :read_all, on: :collection
    get '/unread_all/', to: 'messages#unread_all', as: :unread_all, on: :collection
  end

# Castings routes
  resources :castings do
    get 'edit_photos', on: :member
    concerns :attachable
    get 'manage', on: :member
    get 'close', on: :member
    get 'cancel', on: :member
    get 'activate', on: :member
    get '/custom/index/:contractor_id', to: 'castings#index_custom', as: :custom_index, on: :collection
    get '/custom/index/invite/:contractor_id/:profile_id', to: 'castings#index_custom_invite', as: :custom_index_invite, on: :collection
    get '/invite/index/', to: 'castings#index_invite', on: :member
    get '/invited/index/', to: 'castings#index_invited', on: :member
    get '/confirmed/index/', to: 'castings#index_confirmed', on: :member
    get '/favorites/index/', to: 'castings#index_favorites', on: :member
    get '/applied/index/', to: 'castings#index_applied', on: :member
    get '/apply/:profile_id', to: 'castings#apply', as: :apply, on: :member
    get '/invite/:profile_id', to: 'castings#invite', as: :invite, on: :member
    get '/confirm/:profile_id', to: 'castings#confirm', as: :confirm, on: :member
  end

# Bookings routes
  resources :bookings do
    get '/custom/index/', to: 'bookings#index_custom', as: :custom_index, on: :collection
    get '/confirm/:profile_id', to: 'bookings#confirm', as: :confirm, on: :member
  end

# Admin routes
  scope '/admin' do
    get '/control_panel/', to: 'admin#control_panel', as: :control_panel
    get '/model_pending_review/', to: 'admin#model_pending_review', as: :model_pending_review
  end

# Root
  root to: 'static_pages#home'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
