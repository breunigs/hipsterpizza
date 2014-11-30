require 'spec_helper'

describe MainController, type: :controller do
  let(:basket) { FactoryGirl.create(:basket) }

  describe '#set_nick' do
    it 'stores nick in cookie' do
      patch :set_nick, nick: 'µück'

      expect(cookies['_hipsterpizza_nick']).to eql 'µück'
    end

    it 'redirects to refer if present' do
      allow(controller.request).to receive(:referer).and_return 'https://www.yrden.de'

      patch :set_nick, nick: 'µück'

      expect(response).to redirect_to 'https://www.yrden.de'
    end

    it 'redirects to basket if present' do
      controller.instance_variable_set(:@basket, basket)

      patch :set_nick, nick: 'µück'

      expect(response).to redirect_to basket_url(basket)
    end
  end

  describe '#toggle_admin' do
    it 'stores state in a cookie' do
      now = cookies['_hipsterpizza_is_admin']

      patch :toggle_admin

      expect(now).not_to eql cookies['_hipsterpizza_is_admin']
    end

    it 'executing it twice is a no-op' do
      # ensure cookie is present
      patch :toggle_admin
      now = cookies['_hipsterpizza_is_admin']

      patch :toggle_admin
      patch :toggle_admin

      expect(cookies['_hipsterpizza_is_admin']).to eql now
    end

    it 'instructs JS to reload page' do
      patch :toggle_admin

      expect(response.body).to include('reload')
    end
  end
end
