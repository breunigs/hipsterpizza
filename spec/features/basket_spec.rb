# encoding: utf-8

require 'spec_helper'

xdescribe 'Basket', type: :feature do
  submit_link = I18n.t('button.submit_group_order.first_time.text')

  before do
    @basket = basket_create
  end

  it 'can be cancelled' do
    visit basket_path(@basket)
    click_on I18n.t('nav.admin.admin')
    click_link I18n.t('button.cancel.do')

    expect(page).to have_content I18n.t('basket.controller.group_order.cancelled')
    open_admin_menu
    expect(page).to have_link I18n.t('button.cancel.undo')
    expect(page).not_to have_link submit_link

    click_link I18n.t('button.cancel.undo')

    open_admin_menu
    expect(page).to have_link submit_link
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
    expect(page).to have_content I18n.t('basket.controller.reopened')
    expect(page).to have_link I18n.t('nav.admin.admin')

    open_admin_menu(submit_link)
    wait_for_progress_done
    expect(find_field('Nachname').value).to eq 'Tést 123'
  end
end
