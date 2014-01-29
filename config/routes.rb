Hipsterpizza::Application.routes.draw do
  root :to => "main#chooser"

  scope "hipster" do
    resources :basket, only: [:new, :create]

    scope "basket/:basket_uid" do
      get '', to: "basket#show", as: :basket_with_uid
      get 'share', to: "basket#share", as: :share_basket
      get 'set_admin', to: "basket#set_admin", as: :set_admin_basket
      put 'toggle_cancelled', to: 'basket#toggle_cancelled', as: :toggle_cancelled_basket
      get 'submit', to: "basket#submit", as: :submit_basket
    end
    get 'basket', to: "basket#show", as: :basket

    resources :order, only: [:new, :create]
    scope "order/:order_uuid" do
      put 'toggle_paid', to: 'order#toggle_paid', as: :toggle_paid_order
      delete 'destroy', to: 'order#destroy', as: :destroy_order
      get 'edit', to: 'order#edit', as: :edit_order
      put 'copy', to: 'order#copy', as: :copy_order
    end
  end

  # catch all for unmatched /hipster/ routes
  get 'hipster', to: 'main#chooser'
  get 'hipster/*page', to: 'main#chooser'

  # forward all other requests to pizza.de
  match '*any.:ending', to: "passthrough#pass_cached", ending: /swf|css|jpg|png|gif|js/, via: [:get, :post, :put, :delete]
  match '*any', to: "passthrough#pass", via: [:get, :post, :put, :delete]
  match 'pizzade_root', to: "passthrough#pass", via: :get
end
