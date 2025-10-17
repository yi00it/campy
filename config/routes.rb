Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root to: "projects#index", as: :authenticated_root
  end
  root to: "home#index"

  resources :projects do
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

  resources :categories

  get "my-activities", to: "assigned_activities#index", as: :my_activities
end
