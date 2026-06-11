Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  namespace :admin do
    resources :tournaments
    resources :teams
    resources :stadiums
    resources :players
    resources :matches
    resources :goals
    resources :shootout_kicks
    resources :goal_tags
    resources :goal_taggings
    resources :sources
    resources :video_links
    resources :tournament_awards
    resources :video_link_suggestions, only: [:index, :create]
    get  "matches/:match_id/video_timestamps", to: "match_video_timestamps#edit",   as: :match_video_timestamps
    patch "matches/:match_id/video_timestamps", to: "match_video_timestamps#update"
    resources :player_images do
      member do
        patch :set_default
        patch :set_portrait
      end
    end
    post "players/:player_id/scout_images",  to: "player_images#scout",   as: :scout_player_images
    post "players/:player_id/add_image_url", to: "player_images#add_url", as: :add_player_image_url

    post "players/:player_id/stylize_portrait", to: "stylized_portraits#create", as: :stylize_player_portrait
    resources :stylized_portraits, only: [:destroy] do
      member do
        patch :set_selected
      end
    end

    root to: "tournaments#index"
  end

  resources :tournaments, only: [:index, :show], path: "world-cups", param: :year
  resources :matches,     only: [:index, :show], param: :slug
  resources :goals,       only: [:index, :show], param: :slug
  resources :teams,       only: [:show],         param: :slug
  resources :players,     only: [:show],         param: :slug
  get "search", to: "search#index", as: :search

  get "sitemap.xml", to: "sitemaps#show", defaults: { format: :xml }, as: :sitemap

  # Serves stylized portrait PNGs from storage/ (Kamal persistent volume).
  # Route uses an unanchored constraint (Rails forbids \A\z in routes);
  # PortraitsController#show re-validates with the anchored FILENAME_RE.
  get "portraits/:filename", to: "portraits#show", as: :portrait,
      constraints: { filename: /[a-z0-9][a-z0-9\-_]*\.png/ }

  root "tournaments#index"
end
