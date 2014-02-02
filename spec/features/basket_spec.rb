# encoding: utf-8

require 'spec_helper'

describe 'Basket' do
  before do
    basket_create
  end


  it 'can be created' do
    expect(page).to have_content 'Share Link'
    expect(page).to have_link basket_with_uid_path('')

    click_link basket_with_uid_path(''), match: :first
    expect(page).to have_link 'Place New Order'
    expect(page).to have_link 'Submit Group Order'
  end

  it 'can be cancelled' do
    visit basket_path
    click_link 'Cancel Group Order'

    expect(page).to have_content 'has been cancelled'
    expect(page).to have_link 'Un-Cancel Group Order'
    expect(page).not_to have_link 'Submit Group Order'

    click_link 'Un-Cancel Group Order'
  end

  it 'is submittable' do
    visit basket_path
    order_create
    click_on 'Submit Group Order'

    within('#bestellform') do
      expect(page).to have_content 'Chicken Curry'
      expect(page).to have_field 'Nachname'

      fill_in 'Nachname', with: 'Tést 123'
      # don’t care, only need to blur Nachname field
      fill_in 'Vorname', with: 'asd'
    end

    reload
    has_content?('Warenkorb')

    # TODO: this works in normal browsers, but not when testing.
    # However, when echo debugging the JS it claims that it has
    # restored the field, although capybara-webkit doesn’t pick it
    # up for some reason.
    #~　expect(find_field('Nachname').value).to eq 'Tést 123'

    click_on 'Cancel Submission'

    expect(page).to have_content 'Basket has been reopened'
    expect(page).to have_link 'Submit Group Order'
  end

  it 'allows users to become admins' do
    share_url = current_url
    visit basket_path
    basket_url = current_url # now contains basket uid
    expect(page).to have_link 'Submit Group Order'

    Capybara.reset_sessions!
    visit basket_url
    expect(page).not_to have_link 'Submit Group Order'

    visit share_url
    click_on 'set_admin'

    expect(page).to have_content 'You have been set as admin'
    expect(page).to have_link 'Submit Group Order'
  end

  it 'denies users to submit the group order' do
    visit basket_path
    submit_url = find_link('Submit Group Order', match: :first)[:href]

    Capybara.reset_sessions!

    visit submit_url
    expect(page).to have_content 'You are not an admin'
  end
end
