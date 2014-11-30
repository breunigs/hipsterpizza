require 'spec_helper'

describe BasketController, type: :controller do
  let(:basket) { FactoryGirl.create(:basket) }

  describe '#new' do
    context 'pinning' do
      include_context 'pinning'

      it 'redirects to existing, editable basket' do
        PINNING['single_basket_mode'] = true
        expect(basket.editable?).to eql true

        get :new

        expect(response).to redirect_to basket_path(basket)
      end

      it 'directly creates new basket if all needed fields are pinned' do
        PINNING['shop_name'] = 'Pinned Shop'
        PINNING['shop_url'] = '/hipster/pinned_shop/fake'
        PINNING['shop_fax'] = '+490000000000000'

        get :new
        basket = Basket.first

        expect(basket).not_to be_nil
        expect(response).to redirect_to share_basket_path(basket)
      end

      it 'redirects to pinned shop URL' do
        PINNING['shop_url'] = '/hipster/pinned_shop/fake'
        get :new
        expect(response.redirect_url).to include '/hipster/pinned_shop/fake'
      end
    end

    it 'redirects to Pizza.de root path' do
      get :new
      expect(response).to redirect_to root_service_path(:pizzade)
    end

    it 'sets correct mode cookie' do
      get :new
      expect(cookies['_hipsterpizza_mode']).to eql 'pizzade_basket_new'
    end

  end

  describe '#create' do
    let(:params) { FactoryGirl.attributes_for(:basket) }

    it 'creates new basket' do
      post :create, params
      expect(Basket.first).not_to be_nil
    end

    it 'sets admin cookie' do
      post :create, params
      expect(cookies['_hipsterpizza_is_admin']).to eql 'true'
    end

    it 'redirects to share page' do
      post :create, params
      expect(response).to redirect_to share_basket_path(Basket.first)
    end

    it 'complains about missing fields' do
      post :create
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to root_path
    end

    context 'pinning' do
      include_context 'pinning'

      it 'skips share page in single basket mode' do
        PINNING['single_basket_mode'] = true
        post :create, params
        expect(response).to redirect_to basket_path(Basket.first)
      end
    end
  end

  describe '#show' do
    pending
  end

  describe '#unsubmit' do
    pending
  end

  describe '#set_submit_time' do
    pending
  end

  describe '#delivery_arrived' do
    pending
  end

  describe '#share' do
    pending
  end

  describe '#toggle_cancelled' do
    pending
  end

  describe '#pdf' do
    pending
  end

  describe '#find_changes' do
    before(:all) do
      BC = BasketController.new
      @basket = Basket.new
      BC.instance_variable_set(:@basket, @basket)
    end

    before do
      @basket.updated_at = Time.now
      BC.params = {}
    end

    it 'reports newer @basket timestamp as change' do
      BC.params = { ts_basket: (Time.now - 1.minute).to_i }
      BC.send(:find_changes)
      expect(BC.instance_variable_get(:@basket_changed)).to be true
    end

    it 'doesn’t report equal @basket timestamp as change' do
      BC.params = { ts_basket: @basket.updated_at.to_i }
      BC.send(:find_changes)
      expect(BC.instance_variable_get(:@basket_changed)).to be false
    end

    it 'doesn’t report older @basket timestamp as change' do
      BC.params = { ts_basket: (Time.now + 1.minute).to_i }
      BC.send(:find_changes)
      expect(BC.instance_variable_get(:@basket_changed)).to be false
    end

    it 'reports deleted @order as change' do
      BC.params = { ts_order: Time.now.to_i }
      BC.send(:find_changes)
      expect(BC.instance_variable_get(:@order_changed)).to be true
    end

    context 'with @order' do
      before(:all) do
        @order = Order.new
        BC.instance_variable_set(:@order, @order)
      end

      before do
        @order.updated_at = Time.now
      end

      it 'reports new @order as change' do
        BC.send(:find_changes)
        expect(BC.instance_variable_get(:@order_changed)).to be true
      end

      it 'doesn’t report older @order timestamp as change' do
        BC.params = { ts_order: (Time.now + 1.minute).to_i }
        BC.send(:find_changes)
        expect(BC.instance_variable_get(:@order_changed)).to be false
      end
    end
  end
end
