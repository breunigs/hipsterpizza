Hipsterpizza::Application.routes.draw do
  root :to => "main#chooser"

  scope "hipster" do
    resources :basket#, only: [:index, :new, :create]
    resources :order#, only: [:index, :new, :create]
  end


  # forward all other requests to pizza.de
  match '*any.:ending', to: "passthrough#pass_cached", ending: /swf|css|jpg|png|gif|js/, via: [:get, :post, :put, :delete]
  match '*any', to: "passthrough#pass", via: [:get, :post, :put, :delete]
  match 'pizzade_root', to: "passthrough#pass", via: :get
end
