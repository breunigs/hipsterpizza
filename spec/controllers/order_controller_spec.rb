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
      patch :update, common_params, json: invalid_json
      expect(flash[:error]).not_to be_empty
    end

    it 'handles price difference' do
      expect(controller).to receive(:handle_price_difference)
      patch :update, { json: order.json }.merge(common_params)
    end

    it 'redirects to basket' do
      patch :update, common_params
      expect(response).to redirect_to basket
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


  # def ensure_basket_editable
  #   if @basket.cancelled?
  #     flash[:error] = I18n.t('order.controller.cancelled')
  #     redirect_to @basket
  #   elsif @basket.submitted?
  #     prefix = 'order.controller.already_submitted'
  #     flash[:error] = I18n.t("#{prefix}.main")
  #     flash[:error] << I18n.t("#{prefix}.has_order", order: @order) if @order
  #     redirect_to @basket
  #   end
  # end

  # def flash_error_msgs(order)
  #   return if order.errors.none?
  #   msgs = errors_to_fake_list(order)
  #   flash[:error] = I18n.t('order.controller.failure', msgs: msgs)
  # end

  describe '#handle_price_difference' do
    before do
      controller.instance_variable_set(:@order, order)
    end

    context 'more expensive' do
      let(:pay) { 10 }
      let(:pay_tip) { 15 }

      def run
        controller.send(:handle_price_difference, pay, pay_tip)
      end

      it 'marks order as not paid' do
        order.update_attribute(:paid, true)
        run
        expect(order.paid?).to eql false
      end

      it 'renders price template' do
        run
        expect(response).to render_template('order/_price')
      end
    end
  end

  # def handle_price_difference(pay, pay_tip)
  #   i18n_key = if pay == 0
  #     'no_change'
  #   elsif pay < 0
  #     'take'
  #   else
  #     @order.update_attribute(:paid, false)
  #     'give'
  #   end

  #   fake = OpenStruct.new(sum: pay, sum_with_tip: pay_tip)
  #   price = render_to_string 'order/_price', layout: false, order: fake

  #   flash[:info] = I18n.t('order.controller.update') << ' '
  #   flash[:info] << I18n.t("order.controller.money.#{i18n_key}", price: price)
  # end

  # def require_order
  #   @order = Order.friendly.find(params[:order_id]) rescue nil
  #   return if @order
  #   flash[:error] = t('order.controller.invalid_uuid')
  #   redirect_to @basket
  # end
end
