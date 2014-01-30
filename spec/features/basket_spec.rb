# encoding: utf-8

require 'spec_helper'

describe 'Basket' do
  subject { page }

  it 'allows to create basket for some shop' do
    visit root_path
    click_link 'Create New Basket'

    fill_in 'plzsearch_input', with: '12347'
    has_content?('12347 Berlin')

    click_link 'Lieferservice suchen'
    click_link 'Indian Curry'

    within('#hipsterTopBar') do
      click_on 'Choose Indian Curry'
    end

    expect(page).to have_content 'Share Link'
    expect(page).to have_link basket_with_uid_path('')

    click_link basket_with_uid_path(''), match: :first
    expect(page).to have_link 'Place New Order'
    expect(page).to have_link 'Submit Group Order'
  end

end
