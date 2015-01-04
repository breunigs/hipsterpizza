require 'spec_helper'

describe 'replay and storing', type: :feature do
  describe 'for pizza.de' do
    let(:basket) { FactoryGirl.create(:real_basket_pizzade) }
    before { visit basket_path(id: basket.uid) }

    it 'makes a proper copy of the item' do
      ## testing replay ##
      click_on I18n.t('order_table.menu')
      click_link I18n.t('button.copy_order.button')

      using_wait_time 30 do
        expect(page).to have_no_content I18n.t('please_wait')
        expect(page).to have_button I18n.t('modes.order_new.place.button')
      end

      ## testing saving ##
      accept_prompt(with: 'some unused nick') do
        click_button I18n.t('modes.order_new.place.button')
      end

      basket.reload
      expect(basket.orders.count).to eql 2

      ## testing replay & save produce exact same item ##
      existing_order = basket.orders.first.json_parsed
      copied_order = basket.orders.last.json_parsed

      # ignore differences in pricing
      copied_order.each { |item| item['price'] = 0 }
      existing_order.each { |item| item['price'] = 0 }

      expect(copied_order).to match_array existing_order
    end
  end
end

