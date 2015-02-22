require 'spec_helper'

describe 'Pizza.de Login', type: :feature do
  before do
    visit root_path
    click_on I18n.t('main.chooser.new_basket.link')
  end

  it 'reports login failure properly' do
    visit root_path + 'profil/login'

    within 'form[name=login]' do
      fill_in 'user_name', with: 'test'
      fill_in 'password', with: 'test'
      click_on 'einloggen'
    end

    expect(page).to have_selector 'td.error'
  end
end
