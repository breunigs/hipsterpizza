require 'spec_helper'

describe OrderController, type: :controller do
  let(:basket) { FactoryGirl.create(:basket_with_orders) }
  let(:order) { basket.orders.first }
  let(:common_params) { {basket_id: basket.uid, order_id: order.uuid} }

  describe '#new' do
    it 'redirects to shop' do
      get :new, basket_id: basket.uid
      # TODO: clean up once "redirect_to_shop" does not include pizza.de
      # specific parameters
      expect(response.redirect_url).to include basket.full_path
    end

    it 'sets mode cookie' do
      get :new, basket_id: basket.uid
      expect(cookies['_hipsterpizza_mode']).to include 'order_new'
    end
  end

  describe '#edit' do
    it 'sets mode cookie' do
      get :edit, common_params
      expect(cookies['_hipsterpizza_mode']).to include 'order_edit'
    end

    it 'sets replay cookie' do
      get :edit, common_params
      expect(cookies['_hipsterpizza_replay']).to eql "order nocheck #{order.uuid}"
    end

    it 'redirects to shop' do
      get :edit, common_params
      # TODO: clean up once "redirect_to_shop" does not include pizza.de
      # specific parameters
      expect(response.redirect_url).to include basket.full_path
    end
  end

  describe '#save' do
    it 'creates a saved order' do
      expect {
        post :save, common_params
      }.to change { SavedOrder.count }.by(1)
    end

    it 'stores nick in saved order if available' do
      cookies['_hipsterpizza_nick'] = 'Derpina'
      post :save, common_params
      expect(SavedOrder.first.nick).to eql 'Derpina'
    end

    it 'instructs JS to disable the button' do
      post :save, common_params
      expect(JSON.parse(response.body)).to include('disable' => true)
    end

    it 'creates a saved order with matching JSON' do
      post :save, common_params
      expect(SavedOrder.first.json).to eql order.json
    end

    it 'reports an error if JSON is invalid' do
      order.json = ' { incorrect'
      order.save(validate: false)
      post :save, common_params
      expect(JSON.parse(response.body)).to include('error')
    end
  end

  describe '#update' do
    it 'reports an error of JSON is invalid' do
      invalid_json = ' { incorrect'
      expect {
        patch :update, { json: invalid_json }.merge(common_params)
      }.to raise_error(JSON::ParserError)
    end

    it 'handles price difference' do
      expect(controller).to receive(:handle_price_difference)
      patch :update, { json: order.json }.merge(common_params)
    end

    it 'redirects to basket' do
      patch :update, common_params
      expect(response).to redirect_to basket
    end

    it 'saves new JSON to DB' do
      json = %|[{"price":2.5,"prod":"club mate","extra":[]}]|
      patch :update, { json: json }.merge(common_params)
      order.reload
      expect(order.json).to eql json
    end
  end

  describe '#create' do
    let!(:params_for_order) do
      { basket_id: basket.id }.merge(FactoryGirl.attributes_for(:order))
    end

    it 'stores order to DB' do
      expect {
        post :create, params_for_order
      }.to change { Order.count }.by(1)
    end

    it 'rejects order if basket is cancelled' do
      basket.cancelled = true
      basket.save
      expect {
        post :create, params_for_order
      }.not_to change { Order.count }
    end

    it 'rejects order if basket is submitted already' do
      basket.submitted = Time.now
      basket.save
      expect {
        post :create, params_for_order
      }.not_to change { Order.count }
    end

    it 'order is associated with basket' do
      expect {
        post :create, params_for_order
      }.to change { basket.orders.count }.by(1)
    end

    it 'renders price flash message' do
      post :create, params_for_order
      expect(response).to render_template 'order/_price'
      expect(flash[:info]).not_to be_empty
    end

    it 'redirects to basket' do
      post :create, params_for_order
      expect(response).to redirect_to basket
    end

    it 'shows error if nick missing' do
      post :create, basket_id: basket.id, json: []
      expect(flash[:error]).not_to be_empty
    end

    it 'shows error if JSON missing' do
      post :create, basket_id: basket.id, nick: 'testnick'
      expect(flash[:error]).not_to be_empty
    end
  end

  describe '#toggle_paid' do
    it 'is a no-op if executed twice' do
      status = order.paid?

      patch :toggle_paid, common_params
      patch :toggle_paid, common_params

      order.reload
      expect(order.paid?).to eql status
    end

    it 'displays a flash message' do
      patch :toggle_paid, common_params
      expect(flash[:info]).to include order.nick
    end

    it 'redirects to basket unless XHR' do
      patch :toggle_paid, common_params
      expect(response).to redirect_to basket
    end

    it 'returns empty response if XHR' do
      xhr :patch, :toggle_paid, common_params
      expect(response.status).to eql 200
      expect(response.body).to eql '{}'
    end
  end

  describe '#destroy' do
    context 'as admin' do
      before { cookies['_hipsterpizza_is_admin'] = 'true' }

      it 'removes other people’s orders' do
        expect {
          delete :destroy, common_params
        }.to change { basket.orders.count }.by(-1)
      end
    end

    context 'with different nick from order' do
      before { cookies['_hipsterpizza_nick'] = 'Some Other Nick' }

      it 'shows warning if trying to remove other people’s orders' do
        delete :destroy, common_params
        expect(flash[:warn]).not_to be_empty
      end

      it 'does not remove other people’s orders' do
        expect {
          delete :destroy, common_params
        }.not_to change { basket.orders.count }
      end

    end

    context 'with same nick as in order' do
      before { cookies['_hipsterpizza_nick'] = basket.orders.first.nick }

      it 'removes own order' do
        expect {
          delete :destroy, common_params
        }.to change { basket.orders.count }.by(-1)
      end

      it 'shows message after removal' do
        delete :destroy, common_params
        expect(flash[:info]).not_to be_empty
      end

      it 'shows reminder to take money from pile if paid' do
        patch :toggle_paid, common_params

        delete :destroy, common_params

        expect(response).to render_template('order/_price')
      end
    end

    it 'redirects to basket' do
      delete :destroy, common_params
      expect(response).to redirect_to basket
    end
  end

  describe '#copy' do
    before { cookies['_hipsterpizza_nick'] = 'Derpina' }

    let(:params) {
      {
        basket_id: basket.uid,
        order_id: order.uuid,
        nick: 'somenick',
      }
    }

    context 'recent order' do
      it 'copies the entry directly for 1:1 orders' do
        expect {
          put :copy, { mode: 'insta' }.merge(params)
        }.to change { basket.orders.count }.by(1)
      end

      it 'redirects to basket for 1:1 orders' do
        put :copy, { mode: 'insta'}.merge(params)
        expect(response).to redirect_to basket
      end
    end

    context 'old order' do
      let(:order) { FactoryGirl.create(:order, created_at: 5.days.ago, basket_id: basket.id )}

      it 'redirects to shop' do
        put :copy, params
        # TODO: clean up once "redirect_to_shop" does not include pizza.de
        # specific parameters
        expect(response.redirect_url).to include basket.full_path
      end

      it 'sets correct cookies' do
        put :copy, params
        expect(cookies['_hipsterpizza_replay']).to eql "order check #{order.uuid}"
      end
    end
  end

  describe '#ensure_basket_editable' do
    before do
      controller.instance_variable_set(:@basket, basket)
      allow(controller).to receive(:redirect_to)
    end

    it 'does not assign error if basket editable' do
      controller.send(:ensure_basket_editable)
      expect(flash[:error]).to be_blank
    end

    it 'sets an error if basket cancelled' do
      basket.cancelled = true
      controller.send(:ensure_basket_editable)
      expect(flash[:error]).not_to be_blank
    end

    it 'sets an error if basket already submitted' do
      basket.submitted = Time.now
      controller.send(:ensure_basket_editable)
      expect(flash[:error]).not_to be_blank
    end
  end

  describe '#handle_price_difference' do
    before { controller.instance_variable_set(:@order, order) }
    let(:pay) { 0 }

    def run
      controller.send(:handle_price_difference, pay, pay)
    end

    it 'renders price template' do
      run
      expect(response).to render_template('order/_price')
    end

    it 'adds flash message' do
      run
      expect(flash[:info]).not_to be_empty
    end

    context 'more expensive' do
      let(:pay) { 10 }

      it 'marks order as not paid' do
        order.update_attribute(:paid, true)
        run
        expect(order.paid?).to eql false
      end
    end

    context 'cheaper' do
      let(:pay) { -10 }

      it 'keeps order marked as paid' do
        order.update_attribute(:paid, true)
        run
        expect(order.paid?).to eql true
      end
    end
  end
end
