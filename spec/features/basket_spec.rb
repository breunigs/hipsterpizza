# encoding: utf-8

require 'spec_helper'

xdescribe 'Basket', type: :feature do
  submit_link = I18n.t('button.submit_group_order.first_time.text')

  before do
    @basket = basket_create
  end

  it 'is submittable' do
    visit basket_path(@basket)
    order_create

    open_admin_menu(submit_link)
    wait_for_progress_done

    within('#bestellform') do
      expect(page).to have_content 'Chicken Curry'
      expect(page).to have_field 'Nachname'

      fill_in 'Nachname', with: 'Tést 123'
      # don’t care, only need to blur Nachname field
      fill_in 'Vorname', with: 'asd'
    end

    click_on I18n.t('modes.basket_submit.cancel.button')

    open_admin_menu(submit_link)
    wait_for_progress_done
    expect(find_field('Nachname').value).to eq 'Tést 123'
  end
end
