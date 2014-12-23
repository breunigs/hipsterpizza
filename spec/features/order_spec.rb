# encoding: utf-8

require 'spec_helper'

describe 'Order', type: :feature do
  xcontext 'with existing order' do
    before do
      basket_with_order_create
    end

    it 'can be edited' do
      click_on I18n.t('basket.my_order.dropdown')
      click_on I18n.t('basket.my_order.edit.text')

      wait_until_content('Summe')

      # remove previous order
      remove_button = '#bestellform .btn-v01.btn-remove'
      first(remove_button).click
      # wait until the animation is definitely over before going on
      sleep 0.5
      expect(page).not_to have_css(remove_button)
      expect(page).not_to have_css('.cartitems-item')

      click_on('Geflügel')
      click_on('Chicken Sabzi', match: :first)

      click_on I18n.t('modes.order_edit.place.button')
      expect(page).to have_content 'Chicken Sabzi'
      expect(page).not_to have_content 'Chicken Curry'

      expect(page).to have_content I18n.t('order.controller.update')
    end

    it 'shows error when adding to cancelled basket' do
      open_admin_menu I18n.t('button.cancel.do')
      visit new_basket_order_path(@basket)
      expect(page).to have_content I18n.t('order.controller.cancelled')
    end

    it 'can be copied' do
      click_on I18n.t('order_table.menu')
      click_link I18n.t('button.copy_order.button')
      # wait for page to recognize non-empty basket
      sleep 1.1

      save_and_open_page
      binding.pry
      accept_nick { click_on I18n.t('modes.order_new.place.button') }

      # three = two table entries + user’s own display
      expect(page).to have_content('Chicken Curry', count: 3)
    end

    context 'that has been paid' do
      before do
        click_on I18n.t('button.toggle_paid.not_paid.button'), match: :first
        wait_until_content I18n.t('basket.my_order.has_paid')
        click_on I18n.t('basket.my_order.dropdown')
        click_on I18n.t('basket.my_order.edit.text')
        wait_for_progress_done
        wait_until_content 'Summe'
      end

      it 'keeps order marked as paid if price didn’t change' do
        click_on I18n.t('modes.order_edit.place.button')
        expect(page).to have_content I18n.t('order.controller.update')
        expect(page).to have_content I18n.t('order.controller.money.no_change')
        expect(page).to have_content I18n.t('basket.my_order.has_paid')
      end

      it 'marks order as not paid if price increases' do
        click_on('Geflügel')
        click_on('Chicken Sabzi', match: :first)
        click_on I18n.t('modes.order_edit.place.button')
        expect(page).to have_content I18n.t('order.controller.update')
        # is actually: I18n.t('order.controller.money.give')
        expect(page).to have_content 'Please add'
        expect(page).to have_content I18n.t('basket.my_order.has_not_paid')
      end

      it 'keeps order marked as paid if price decreases' do
        # remove previous order
        remove_button = '#bestellform .btn-v01.btn-remove'
        first(remove_button).click
        # wait until the animation is definitely over before going on
        sleep 0.5
        expect(page).not_to have_css(remove_button)
        expect(page).not_to have_css('.cartitems-item')

        click_on('Desserts')
        wait_until_content('Mangofrüchte')
        click_on('Mangofrüchte', match: :first)
        sleep 0.5 # wait for animation to finish
        sleep 1.1 # wait for page to recognize non-empty basket
        click_on I18n.t('modes.order_edit.place.button')
        expect(page).to have_content I18n.t('order.controller.update')
        # is actually: I18n.t('order.controller.money.take')
        expect(page).to have_content 'Don’t forget to take'
        expect(page).to have_content I18n.t('basket.my_order.has_paid')
      end
    end
  end

  xcontext 'with existing basket' do
    before do
      @basket = basket_create
      visit basket_path(@basket)
    end

    it 'finds items in sub-categories' do
      # place original order
      click_on I18n.t('basket.new_order_button.link'), match: :first
      click_on 'Getränke'
      sleep 0.5; wait_until_content('Softdrinks')
      click_on 'Cocktails'
      sleep 0.5; wait_until_content('Ananassaft')
      click_on 'Pina Colada', match: :first
      # wait for page to recognize non-empty basket
      sleep 1.1
      accept_nick { click_on I18n.t('modes.order_new.place.button') }

      # copy this order
      # visit_basket_as_new_user
      click_on I18n.t('order_table.menu')
      accept_confirm do
        click_link I18n.t('button.copy_order.button')
      end
      wait_for_progress_done
      # wait for page to recognize non-empty basket
      sleep 1.1
      accept_nick { click_on I18n.t('modes.order_new.place.button') }
      wait_until_content I18n.t('order_table.heading')

      # three = twice in list, once in basket
      expect(page).to have_content('Pina Colada', count: 3)
    end
  end
end
