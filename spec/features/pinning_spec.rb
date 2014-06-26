# encoding: utf-8

require 'spec_helper'
require 'pp'

describe 'Pinning' do
  SHOP_URL = '/indian-curry-berlin-bruesseler-str-17'

  # shortened basket creation scheme, with less checking.
  def basket_create
    visit root_path + '/12347'
    click_link 'Indian Curry'
    wait_until_content('Warenkorb')
    within('#hipsterTopBar') do
      click_on I18n.t('modes.choose_shop.button')
    end
  end

  before do
    # reassign PINNING variable to get rid of the freeze and
    # allow custom assignments. Normally Ruby issues a warning,
    # but in we can ignore it safely in this context.
    silence_warnings { PINNING = { } }
  end

  after(:all) do
    silence_warnings { PINNING = { }.freeze }
  end

  context 'with shop url' do
    before { PINNING['shop_url'] = SHOP_URL }

    it 'skips shop selection' do
      visit root_path
      click_link 'Create New Basket'
      expect(page).to have_content 'Share Link'
    end

    context 'and shop fax and shop name' do
      before do
        PINNING['shop_fax'] = '+49000000000'
        PINNING['shop_name'] = 'TestShop'
      end

      it 'skips shop selection' do
        visit root_path
        click_link 'Create New Basket'
        expect(page).to have_content 'Share Link'
      end
    end
  end

  context 'with single shop mode' do
    before { PINNING['single_basket_mode'] = true }

    it 'skips share page on basket creation' do
      basket_create
      expect(page).to have_content('Money Pile')
      expect(page).not_to have_content('Share')
    end

    it 'redirects front page to existing basket' do
      basket_create
      old_url = current_url
      visit root_path
      expect(page).to have_content('Money Pile')
      expect(current_url).to eql(old_url)
    end
  end
end
