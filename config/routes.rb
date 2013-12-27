Hipsterpizza::Application.routes.draw do

  root :to => "passthrough#pass"
  match '*any', to: "passthrough#pass", via: [:get, :post, :put, :delete]
end
