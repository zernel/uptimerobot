Rails.application.routes.draw do
  devise_for :users

  # Dashboard
  root "dashboard#index"

  # Monitors
  resources :monitors do
    member do
      post :pause
      post :resume
      post :reset
    end
    resources :check_results, only: [:index]
    resources :incidents, only: [:index, :show]
  end

  # Monitor Groups
  resources :monitor_groups

  # Tags
  resources :tags

  # Notification Channels
  resources :notification_channels

  # Status Pages
  resources :status_pages do
    member do
      get :preview
    end
    resources :announcements do
      resources :announcement_updates, only: [:create]
    end
  end

  # Public Status Page
  get "/status/:slug", to: "public_status_pages#show", as: :public_status_page

  # Heartbeat endpoint
  get "/heartbeat/:token", to: "heartbeat#ping", as: :heartbeat

  # Maintenance Windows
  resources :maintenance_windows

  # Incidents
  resources :incidents, only: [:index, :show] do
    resources :incident_comments, only: [:create]
  end

  # GoodJob Dashboard (admin only)
  authenticate :user, ->(u) { u.admin? } do
    mount GoodJob::Engine => '/good_job'
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
