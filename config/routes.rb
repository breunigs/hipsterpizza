Hipsterpizza::Application.routes.draw do
  root :to => "main#chooser"

  scope "hipster" do
    resources :basket, only: [:new, :create]

    scope "basket/:uid" do
      get '', to: "basket#show", as: :basket
      get 'share', to: "basket#share", as: :share_basket
      get 'set_admin', to: "basket#set_admin", as: :set_admin_basket
    end
    get 'basket', to: "basket#show"

    resources :order#, only: [:index, :new, :create]
  end


  # forward all other requests to pizza.de
  match '*any.:ending', to: "passthrough#pass_cached", ending: /swf|css|jpg|png|gif|js/, via: [:get, :post, :put, :delete]
  match '*any', to: "passthrough#pass", via: [:get, :post, :put, :delete]
  match 'pizzade_root', to: "passthrough#pass", via: :get
end
