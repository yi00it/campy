Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root to: "projects#index", as: :authenticated_root
  end
  root to: "home#index"

  resources :projects do
  resources :todos, shallow: true do
    member do
      patch :toggle_done
    end
    resources :comments, only: [:create, :destroy]  # if you added comments already
  end
end
end
