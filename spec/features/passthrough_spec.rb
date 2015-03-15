# encoding: utf-8

require 'spec_helper'

describe 'Passthrough', type: :feature do
  before do
    visit root_path
    link = I18n.t('main.chooser.new_basket.link', provider: 'Pizza.de')
    click_on link
  end

  xit 'renders pizza.de root page' do
    expect(page).to have_content 'Pizza Lieferservice und Pizzaservice'
  end

  xit 'renders shop page' do
    visit root_path + FactoryGirl.build_stubbed(:real_basket_pizzade).full_path
    expect(page).to have_content 'Indian Curry | Brüsseler Str. 17 | 13353 Berlin'
  end

  xit 'replaces content' do
    visit root_path + '0_image/pizza-de_logoshop_v8.gif'
    expect(current_url).to end_with 'hipster/assets/blank.png'
  end
end
