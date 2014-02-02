# encoding: utf-8

require 'spec_helper'

describe 'Main' do
  it 'warns when given invalid basket uid' do
    visit root_path
    fill_in 'basket_uid', with: 'asd'
    click_on 'Use Basket'

    expect(page).to have_content 'Invalid Basket-ID'
  end
end
