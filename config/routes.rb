Hipsterpizza::Application.routes.draw do
  root :to => "passthrough#pass"

  # forward all other requests to pizza.de
  match '*any.:ending', to: "passthrough#pass_cached", ending: /swf|css|jpg|png|gif|js/, via: [:get, :post, :put, :delete]
  match '*any', to: "passthrough#pass", via: [:get, :post, :put, :delete]
end
