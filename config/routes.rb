Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root to: "dashboards#show", as: :authenticated_root
  end
  root to: "home#index"

  resources :projects do
    member do
      get :gantt
    end
    resources :project_memberships, only: [:create, :update, :destroy]
    resources :project_invitations, only: [:destroy]
    resource :activities_import, only: [:new, :create] do
      get :template, on: :collection
    end
    resources :activities, shallow: true do
      member do
        patch :toggle_done
      end
      resources :comments, only: [:create, :destroy] do
        resources :comment_reactions, only: [:create]
      end
    end
  end

  resources :disciplines
  resources :zones
  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:create]
  end

  resources :users, only: [:show]

  resource :settings, only: [:show, :update], controller: "settings"

  get "my-activities", to: "assigned_activities#index", as: :my_activities

  resource :calendar, only: [:show], controller: "calendar"
  resources :calendar_events, except: [:show]

  resources :notifications, only: [:index] do
    member do
      post :mark_as_read
    end
    collection do
      post :mark_all_as_read
      get :unread_count
      get :dropdown
    end
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
