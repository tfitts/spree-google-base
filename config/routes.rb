Spree::Core::Engine.routes.append do
  namespace :admin do
    resource :google_base_settings
  end
end
