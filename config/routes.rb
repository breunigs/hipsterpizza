Hipsterpizza::Application.routes.draw do
  root :to => "passthrough#pass"

  # forward all other requests to pizza.de
  match '*any', to: "passthrough#pass", via: [:get, :post, :put, :delete]
end
