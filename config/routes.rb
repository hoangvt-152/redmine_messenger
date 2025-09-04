# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

# Don't create routes for repositories resources with only: []
# do not override Redmine's routes.
resources :projects, only: [] do
  resource :messenger_setting, only: %i[show update]
end
