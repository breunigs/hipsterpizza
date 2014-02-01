# encoding: utf-8

require 'spec_helper'

describe 'Basket' do
  subject { page }

  it 'allows to create basket for some shop' do
    basket_create

    expect(page).to have_content 'Share Link'
    expect(page).to have_link basket_with_uid_path('')

    click_link basket_with_uid_path(''), match: :first
    expect(page).to have_link 'Place New Order'
    expect(page).to have_link 'Submit Group Order'
  end

  it 'allows group order cancel' do
    basket_create
    visit basket_path
    click_link 'Cancel Group Order'

    expect(page).to have_content 'has been cancelled'
    expect(page).to have_link 'Un-Cancel Group Order'
    expect(page).not_to have_link 'Submit Group Order'
  end
end
