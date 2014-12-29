
require 'spec_helper'

describe 'Order', type: :feature do
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
