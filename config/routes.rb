Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root to: "projects#index", as: :authenticated_root
  end
  root to: "home#index"

  resources :projects do
    member do
      get :gantt
    end
    resources :project_memberships, only: [:create, :destroy]
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

  get "my-activities", to: "assigned_activities#index", as: :my_activities
end
