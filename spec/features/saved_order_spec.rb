# encoding: utf-8

require 'spec_helper'

describe 'SavedOrder' do
  SAVED_ORDER_NAME = "Tėst 42: Pizza Mo"

  before do
    basket_with_order_create
    page.driver.js_prompt_input = SAVED_ORDER_NAME
    page.driver.accept_js_prompts!
    click_on 'Save My Order'
    wait_until_content 'saved ✓'
  end

  it 'shows saved orders' do
    visit saved_order_index_path
    expect(page).to have_content(SAVED_ORDER_NAME)
  end

  it 'shows previous orders for current user' do
    visit saved_order_index_path
    expect(page).to have_content('Your Previous Orders, Tėst Ñiçk 1_2-3')
    # i.e. never in date column because the basket hasn’t been
    # submitted.
    expect(page).to have_content('never')
  end

  it 'doesn’t show previous orders for current user' do
    visit_basket_as_new_user
    expect(page).not_to have_content('Your Previous Orders, Tėst Ñiçk 1_2-3')
  end

  it 'offers new users to identify by nick' do
    visit_basket_as_new_user
    visit saved_order_index_path
    expect(page).to have_button('Set Nickname')
  end

  it 'allows saved orders to be destroyed' do
    visit saved_order_index_path
    click_on 'destroy'
    # it keeps the previous orders intact
    expect(page).to have_content('Chicken Curry')
    expect(page).to have_content('No saved orders yet')

    within('table') do
      expect(page).not_to have_content(SAVED_ORDER_NAME)
    end
  end

  it 'can be copied' do
    visit_basket_as_new_user
    visit saved_order_index_path
    fill_in 'nick', with: 'new user'
    click_on 'Set Nickname'
    click_on 'insta order this'
    wait_until_content 'General Options'
    expect(page).to have_content 'Your Order, new user'
  end
end
