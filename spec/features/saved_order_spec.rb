# encoding: utf-8

require 'spec_helper'

xdescribe 'SavedOrder', type: :feature do
  SAVED_ORDER_NAME = 'Tėst 42: Pizza Mo'
  PREV_ORDERS = I18n.t('saved_order.index.previous_orders.heading')

  before do
    basket_with_order_create
    click_on I18n.t('basket.my_order.dropdown')
    accept_prompt(with: SAVED_ORDER_NAME) do
      click_on I18n.t('button.save_order.link.my')
    end
    wait_until_content I18n.t('button.save_order.link.saved')
  end

  it 'shows saved orders' do
    visit saved_order_index_path
    expect(page).to have_content(SAVED_ORDER_NAME)
  end

  it 'shows previous orders for current user' do
    visit saved_order_index_path
    expect(page).to have_content(PREV_ORDERS)
    # i.e. never in date column because the basket hasn’t been submitted.
    expect(page).to have_content(I18n.t('time.never'))
  end

  it 'doesn’t show previous orders for current user' do
    visit_basket_as_new_user
    visit saved_order_index_path
    expect(page).to have_content(I18n.t('saved_order.index.specify_nick'))
  end

  it 'offers new users to identify by nick' do
    visit_basket_as_new_user
    visit saved_order_index_path
    expect(page).to have_button(I18n.t('nick.button.manually'))
  end

  it 'allows saved orders to be destroyed' do
    visit saved_order_index_path
    click_on I18n.t('saved_order.index.saved_orders.destroy.button')
    # it keeps the previous orders intact
    expect(page).to have_content('Chicken Curry')
    expect(page).to have_content(I18n.t('saved_order.index.saved_orders.none'))

    within('table') do
      expect(page).not_to have_content(SAVED_ORDER_NAME)
    end
  end

  it 'can be copied' do
    nick = 'new user'
    visit_basket_as_new_user
    visit saved_order_index_path
    click_on I18n.t('nick.button.manually')
    within('.modal-dialog') do
      fill_in 'nick', with: nick
      click_on I18n.t('nick.form.set_nick')
    end
    click_on I18n.t('button.insta_copy_order.button'), match: :first
    # i.e. insta-copy is done and we are back on the group basket view
    wait_until_content I18n.t('order_table.heading')
    expect(page).to have_content I18n.t('basket.my_order.heading', nick: nick)
  end
end
