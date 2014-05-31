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
        get 'unsubmit'
        get 'pdf'

        patch 'toggle_cancelled'
        patch 'delivery_arrived'
        patch 'submit'

        post 'set_submit_time'
      end


      resources :order, except: :index do
        member do
          patch 'toggle_paid'
          post 'save'
          put 'copy'
        end
      end
    end

    resources :saved_order, only: [:index, :destroy] do
      member do
        put 'copy'
      end
    end

    get 'streaming_test', to: "basket_submit#test"
  end

  # catch all for unmatched /hipster/ routes
  get 'hipster', to: 'main#chooser'
  get 'hipster/*page', to: 'main#find'

  # forward all other requests to pizza.de

  # cache static resources for a very long time. Only JS files which are
  # fingerprinted should be stored for an extended period.
  match '*any.:ending', to: 'passthrough#pass_cached', ending: /swf|css|jpg|png|gif/, via: :get
  match '*any.:fingerprint.:ending', to: 'passthrough#pass_cached', ending: 'js', fingerprint: /[a-z0-9]{40}/, via: :get
  match '*any-:fingerprint.:ending', to: 'passthrough#pass_cached', ending: 'js', fingerprint: /[a-z0-9]{40}/, via: :get

  # other elements are usually revalidated each time (using etags) or
  # only stored for relatively short periods.
  match '*any', to: 'passthrough#pass', via: :all

  get 'pizzade_root', to: 'passthrough#pass'
end
