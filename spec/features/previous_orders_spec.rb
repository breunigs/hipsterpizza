# encoding: utf-8

require 'spec_helper'
require 'pp'

describe 'Previous Order' do
  context 'in current basket' do
    it 'asks for nickname if not set' do
      basket_create
      visit basket_path
      click_on 'Show Saved/Previous Orders'
      expect(page).to have_button 'Set Nickname'
    end

    it 'is shown immediately after ordering' do
      basket_with_order_create
      click_on 'Show Saved/Previous Orders'
      expect(page).to have_content 'Chicken Curry'
      expect(page).to have_content 'never'
    end

    it 'can be replayed' do
      basket_with_order_create
      click_on 'Show Saved/Previous Orders'
      click_on 'insta order this'
      wait_until_content 'Your order has been added'
      # 3 = two times in list, once in 'Your Order'
      expect(page).to have_content('Chicken Curry', count: 3)
    end
  end

  context 'in previous basket' do
    before do
      basket_with_order_create
      #visit root_path
      basket_create
      visit basket_path
      # ensure we’re in a new basket
      expect(page).not_to have_content 'Your Order'
    end

    it 'shows previous order from same shop' do
      click_on 'Show Saved/Previous Orders'
      expect(page).to have_content 'Chicken Curry'
    end

    it 'can be replayed' do
      click_on 'Show Saved/Previous Orders'
      click_on 'insta order this'
      wait_until_content 'Your order has been added'
      # 2 = once in list, once in 'Your Order'
      expect(page).to have_content('Chicken Curry', count: 2)
    end
  end
end
