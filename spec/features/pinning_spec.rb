# encoding: utf-8

require 'spec_helper'
require 'pp'

xdescribe 'Pinning', type: :feature do
  SHOP_URL = '/indian-curry-berlin-bruesseler-str-17'

  # shortened basket creation scheme, with less checking.
  def basket_create
    visit root_path
    click_on I18n.t('main.chooser.new_basket.link')
    visit root_path + '/12347'
    click_link 'Indian Curry', match: :first
    wait_until_content('Warenkorb')
    within('#hipsterTopBar') do
      click_on I18n.t('modes.choose_shop.button')
    end
  end

  before do
    # reassign PINNING variable to get rid of the freeze and
    # allow custom assignments. Normally Ruby issues a warning,
    # but we can ignore it safely in this context.
    silence_warnings { PINNING = { } }
  end

  after(:all) do
    silence_warnings { PINNING = { }.freeze }
  end

  context 'with single shop mode' do
    before { PINNING['single_basket_mode'] = true }


    it 'redirects front page to existing basket' do
      basket_create
      old_url = current_url
      visit root_path
      expect(page).to have_content('Money Pile')
      expect(current_url).to eql(old_url)
    end
  end
end
