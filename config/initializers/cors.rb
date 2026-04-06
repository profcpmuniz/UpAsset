# Be sure to restart your server when you modify this file.

# Enable CORS for the API proxy endpoints used by the frontend.
# This ensures the browser can access the /api/* routes if the app is hosted on a different origin.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '/api/*',
      headers: :any,
      methods: [:get, :options]
  end
end
