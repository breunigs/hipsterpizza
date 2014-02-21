Hipsterpizza::Application.routes.draw do
  root to: 'main#chooser'

  scope 'hipster' do
    get 'privacy', to: 'main#privacy'

    resources :basket, only: [:new, :create]

    scope 'basket/:basket_uid' do
      get '', to: 'basket#show', as: :basket_with_uid

      %w(share set_admin unsubmit pdf).each do |res|
        get res, to: "basket##{res}", as: "#{res}_basket"
      end

      %w(toggle_cancelled delivery_arrived).each do |res|
        put res, to: "basket##{res}", as: "#{res}_basket"
      end

      put 'submit', to: "basket_submit#submit", as: "submit_basket"

      post 'set_submit_time', to: 'basket#set_submit_time', as: :set_submit_time_basket
    end
    get 'basket', to: 'basket#find', as: :basket

    resources :order, only: [:new, :create]
    scope 'order/:order_uuid' do
      put 'toggle_paid', to: 'order#toggle_paid', as: :toggle_paid_order
      delete 'destroy', to: 'order#destroy', as: :destroy_order
      post 'update', to: 'order#update', as: :update_order
      post 'save', to: 'order#save', as: :save_order
      get 'edit', to: 'order#edit', as: :edit_order
      put 'copy', to: 'order#copy', as: :copy_order
    end

    resources :saved_order, only: [:index]
    scope 'saved_order/:saved_order_uuid' do
      delete 'destroy', to: 'saved_order#destroy', as: :destroy_saved_order
      put 'copy', to: 'saved_order#copy', as: :copy_saved_order
    end

    get 'streaming_test', to: "basket_submit#test"
  end

  # catch all for unmatched /hipster/ routes
  get 'hipster', to: 'main#chooser'
  get 'hipster/*page', to: 'basket#find'

  # forward all other requests to pizza.de
  match '*any.:ending', to: 'passthrough#pass_cached', ending: /swf|css|jpg|png|gif|js/, via: :all
  match '*any', to: 'passthrough#pass', via: :all
  get 'pizzade_root', to: 'passthrough#pass'
end
