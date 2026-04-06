Rails.application.routes.draw do
  # API proxy routes for the Uphold Explorer frontend.
  get '/api/ticker/:pair', to: 'api#ticker'
  get '/api/assets', to: 'api#assets'
  get '/api/compare/:asset', to: 'api#compare'

  # The frontend is served from public/index.html by the Rails public file server.
end
