require 'spec_helper'

describe SavedOrderController, type: :controller do
  let(:basket) { FactoryGirl.create(:basket) }
  let(:saved_order) { FactoryGirl.create(:saved_order, shop_url: basket.shop_url) }

  describe '#index' do
    context '@basket is available' do
      before { controller.instance_variable_set(:@basket, basket) }

      it 'renders index template' do
        get :index
        expect(response.status).to eql 200
        expect(response).to render_template :index
      end

      it 'finds saved orders' do
        so = saved_order
        get :index
        expect(assigns(:saved).to_a).to eql [so]
      end

      it 'finds previous orders if nick is set' do
        orders = FactoryGirl.create(:basket_with_orders).orders.to_a
        cookies['_hipsterpizza_nick'] = orders.first.nick

        get :index
        expect(assigns(:previous_orders).to_a).to eql orders
      end

      it 'doesn’t show other user’s previous orders' do
        orders = FactoryGirl.create(:basket_with_orders).orders.to_a
        cookies['_hipsterpizza_nick'] = 'some other nick'

        get :index
        expect(assigns(:previous_orders).to_a).to eql []
      end

      it 'allows to set nick if not set' do
        get :index
        expect(response).to render_template 'nick/_button'
      end
    end
  end

  describe '#destroy' do
    before { controller.instance_variable_set(:@basket, basket) }

    it 'redirects back to saved orders page' do
      delete :destroy, saved_order_id: saved_order.uuid
      expect(response).to redirect_to saved_order_index_path
    end

    it 'removes saved order from database' do
      delete :destroy, saved_order_id: saved_order.uuid
      expect(SavedOrder.where(uuid: saved_order.uuid).size).to eql 0
    end

    it 'keeps previous orders intact' do
      prev_orders = FactoryGirl.create(:basket_with_orders).orders.to_a
      cookies['_hipsterpizza_nick'] = prev_orders.first.nick

      delete :destroy, saved_order_id: saved_order.uuid
      expect(controller.send(:find_previous_orders).to_a).to eql prev_orders
    end
  end

  describe '#copy' do
    before { controller.instance_variable_set(:@basket, basket) }

    it 'redirects to shop' do
      put :copy, saved_order_id: saved_order.uuid
      # TODO: clean up once "redirect_to_shop" does not include pizza.de
      # specific parameters
      expect(response.redirect_url).to include basket.full_path
    end

    it 'sets correct replay cookie' do
      put :copy, saved_order_id: saved_order.uuid, mode: :check
      expect(cookies['_hipsterpizza_replay']).to eql "savedorder check #{saved_order.uuid}"
    end
  end
end
