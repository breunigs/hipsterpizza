# encoding: utf-8

require 'spec_helper'

xdescribe 'Previous Order', type: :feature do
  context 'in current basket' do
    it 'offers to set nickname if not done so' do
      @basket = basket_create
      visit basket_path(@basket)
      click_on I18n.t('button.saved_prev_orders.link'), match: :first
      expect(page).to have_button I18n.t('nick.button.manually')
    end

    it 'is shown immediately after ordering' do
      basket_with_order_create
      click_on I18n.t('button.saved_prev_orders.link'), match: :first
      expect(page).to have_content 'Chicken Curry'
      expect(page).to have_content I18n.t('time.never')
    end

    it 'can be replayed' do
      basket_with_order_create
      click_on I18n.t('button.saved_prev_orders.link'), match: :first
      click_on I18n.t('button.insta_copy_order.button')
      wait_until_content I18n.t('order_table.heading')
      # 3 = two times in list, once in 'Your Order'
      expect(page).to have_content('Chicken Curry', count: 3)
    end
  end

  context 'in previous basket' do
    before do
      basket_with_order_create
      @basket = basket_create
      visit basket_path(@basket)
      # ensure we’re in a new basket
      expect(page).not_to have_content 'Your Order'
    end

    it 'shows previous order from same shop' do
      click_on I18n.t('button.saved_prev_orders.link'), match: :first
      expect(page).to have_content 'Chicken Curry'
    end

    it 'can be replayed' do
      click_on I18n.t('button.saved_prev_orders.link'), match: :first
      click_on I18n.t('button.insta_copy_order.button')
      wait_until_content I18n.t('order_table.heading')
      # 2 = once in list, once in 'Your Order'
      expect(page).to have_content('Chicken Curry', count: 2)
    end
  end
end
