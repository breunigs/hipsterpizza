# encoding: utf-8

require 'spec_helper'

describe BasketController do
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
      expect(BC.instance_variable_get(:@basket_changed)).to be_true
    end

    it 'doesn’t report equal @basket timestamp as change' do
      BC.params = { ts_basket: @basket.updated_at.to_i }
      BC.send(:find_changes)
      expect(BC.instance_variable_get(:@basket_changed)).to be_false
    end

    it 'doesn’t report older @basket timestamp as change' do
      BC.params = { ts_basket: (Time.now + 1.minute).to_i }
      BC.send(:find_changes)
      expect(BC.instance_variable_get(:@basket_changed)).to be_false
    end

    it 'reports deleted @order as change' do
      BC.params = { ts_order: Time.now.to_i }
      BC.send(:find_changes)
      expect(BC.instance_variable_get(:@order_changed)).to be_true
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
        expect(BC.instance_variable_get(:@order_changed)).to be_true
      end

      it 'doesn’t report older @order timestamp as change' do
        BC.params = { ts_order: (Time.now + 1.minute).to_i }
        BC.send(:find_changes)
        expect(BC.instance_variable_get(:@order_changed)).to be_false
      end
    end
  end
end
