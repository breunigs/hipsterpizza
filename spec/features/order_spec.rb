# encoding: utf-8

require 'spec_helper'

describe 'Order' do
  before do
    basket_with_order_create
  end

  it 'can be created' do
    expect(page).to have_content 'Your Order'
  end

  it 'paid status can be toggled' do
    click_on 'Mark Order as Paid', match: :first

    # wait until marked as payed and top bar shows admin-progress bar
    # again
    expect(page).to have_content('hand out link to everyone')

    expect(page).to have_content 'You are marked as having paid'
    expect(page).to have_link 'Mark Order as NOT Paid'

    click_on 'Mark Order as NOT Paid', match: :first
    expect(page).to have_content 'You still need to pay'
    expect(page).to have_link 'Mark Order as Paid'
  end

  it 'can be destroyed' do
    page.driver.accept_js_confirms!
    click_on 'Destroy My Order'
    expect(page).to have_content 'Your order has been removed'
    expect(page).not_to have_content 'Chicken Curry'
  end

  it 'can be edited' do
    click_on 'Edit My Order'
    expect(page).to have_content('Warenkorb')

    # remove previous order
    remove_button = '#bestellform .btn-v01.btn-remove'
    first(remove_button).click
    # try again, to help with random CI failures
    first(remove_button).click if has_css?(remove_button)
    expect(page).not_to have_css(remove_button)
    expect(page).not_to have_css('.cartitems-item')

    click_on('Geflügel')
    click_on('Chicken Sabzi', match: :first)

    accept_nick!
    click_on('Update My Order')
    expect(page).to have_content 'Chicken Sabzi'
    expect(page).not_to have_content 'Chicken Curry'

    expect(page).to have_content 'Your order has been updated'
  end

  it 'shows error when adding to cancelled basket' do
    click_link 'Cancel Group Order'
    visit new_order_path
    expect(page).to have_content('This group order has been cancelled')
  end

  it 'can be copied' do
    click_link 'insta-copy'
    # three = two table entries + user’s own display
    expect(page).to have_content('Chicken Curry', count: 3)
  end

  it 'can be saved' do
    page.driver.js_prompt_input = "Tėst 42: Pizza Mo"
    page.driver.accept_js_prompts!

    click_on 'Save My Order'
    expect(page).to have_content('saved ✓')
  end
end
