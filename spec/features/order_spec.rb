# encoding: utf-8

require 'spec_helper'

describe 'Order' do
  it 'manages the life cycle of an order' do
    basket_create
    visit basket_path

    click_on 'Place New Order'
    click_on 'Chicken Curry', match: :first

    page.driver.js_prompt_input = "Tėst Ñiçk 1_2-3"
    page.driver.accept_js_prompts!

    click_on 'Place My Order in Group Basket'

    expect(page).to have_content 'You still need to pay'
    expect(page).to have_content 'Chicken Curry'

    click_on 'Mark Order as Paid', match: :first

    expect(page).to have_content 'You are marked as having paid'
    expect(page).to have_link 'Mark Order as NOT Paid'

    page.driver.accept_js_confirms!
    click_on 'Destroy My Order'
    expect(page).to have_content 'Your order has been removed'
    expect(page).not_to have_content 'Chicken Curry'
  end

end
