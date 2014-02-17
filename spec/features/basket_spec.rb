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
    expect(page).to have_content('Warenkorb')

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

  it 'doesn’t show submit button to users' do
    visit_basket_as_new_user
    expect(page).not_to have_content 'Submit Group Order'
  end

  it 'shows a delivery time estimate' do
    visit basket_path
    order_create

    click_on 'Submit Group Order', match: :first
    visit basket_path

    expect(page).to have_content 'has been submitted at'
    expect(page).to have_content 'less than a minute ago'

    click_on 'Delivery Has Arrived', match: :first
    expect(page).to have_content 'It arrived at'
    expect(page).to have_content 'Time Taken'

    # second basket, should be able to print an estimate now
    basket_with_order_create

    click_on 'Submit Group Order', match: :first
    visit basket_path
    expect(page).to have_content 'it will probably arrive at'
  end

  it 'sets correct submit time' do
    visit basket_path
    click_on 'Submit Group Order', match: :first
    click_on 'Set Submit Time To Now'
    expect(page).to have_content 'less than a minute ago'
  end

  it 'can render a pdf' do
    visit basket_path
    click_on 'Render PDF', match: :first
    expect(page.html).to start_with('%PDF-1')
    # This is always true due to a bug in Rails. See
    # https://github.com/rails/rails/pull/14000
    expect(page.status_code).to eql(200)
  end
end
