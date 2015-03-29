Hipsterpizza::Application.routes.draw do
  root to: 'main#chooser'

  scope 'hipster' do
    get 'privacy', to: 'main#privacy'
    get 'clock.svg', to: 'main#clock', ending: 'svg', as: 'clock'

    patch 'set_nick', to: 'main#set_nick'

    patch 'toggle_admin', to: 'main#toggle_admin'

    resources :basket, only: [:new, :create, :show] do
      member do
        get 'share'
        get 'unsubmit' # TODO: why get?
        get 'pdf'

        patch 'toggle_cancelled'
        patch 'delivery_arrived'
        patch 'submit', to: 'basket_submit#submit'

        post 'set_submit_time'
      end

      resources :order, except: :index, param: :order_id do
        member do
          patch 'toggle_paid'
          post 'save'
          put 'copy'
        end
      end
    end

    resources :saved_order, only: [:index, :destroy], param: :saved_order_id do
      member do
        put 'copy'
      end
    end

    get 'provider_root', to: 'passthrough#provider_root'
    get 'raw', to: 'cors#pass'

    get 'streaming_test', to: 'basket_submit#test'
  end

  # catch all for unmatched /hipster/ routes
  get 'hipster', to: 'main#chooser'
  get 'hipster/*page', to: 'main#find'

  # forward all other requests
  match '*any', to: 'passthrough#pass', via: :all

end
