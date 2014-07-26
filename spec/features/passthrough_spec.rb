# encoding: utf-8

require 'spec_helper'

describe 'Passthrough', type: :feature do
  before do
    visit root_path
    click_on I18n.t('main.chooser.new_basket.link')
  end

  it 'renders pizza.de root page' do
    expect(page).to have_content 'Pizza Lieferservice und Pizzaservice'
  end

  it 'renders shop page' do
    visit root_path + 'indian-curry-berlin-bruesseler-str-17?lgs=102261&ed=406536'
    expect(page).to have_content 'Indian Curry | Brüsseler Str. 17 | 13353 Berlin'
  end

  it 'replaces content' do
    visit root_path + '0_image/pizza-de_logoshop_v8.gif'
    expect(current_url).to end_with 'hipster/assets/blank.png'
  end
end
