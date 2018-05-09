Rails.application.routes.draw do

  #API
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do

      resources :itineraries do
        collection do
          post 'plan'
          post 'email'
        end
      end

      resources :places do
        collection do
          get 'search'
          get 'boundary'
          get 'synonyms'
          get 'blacklist'
          post 'within_area'
        end
      end

      resources :defaults do 
        collection do 
          get 'pass'
          post 'pass' 
        end
      end

      resources :defaults, path: '/:type/defaults', constraints: { type: /internal|external/ }

    end
  end

  #Not API

  root 'settings#index'

  resources :settings, :only => [:index] do
    collection do
      patch 'set_callnride_boundary'
      patch 'set_landmarks_file'
      patch 'set_synonyms_file'
      patch 'set_open_trip_planner'
      patch 'set_blacklisted_places_file'
      patch 'set_global_boundary'
      patch 'set_host'
    end
  end

end
