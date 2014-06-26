# encoding: utf-8

require 'spec_helper'

describe 'Main' do
  it 'warns when given invalid basket uid' do
    visit root_path
    fill_in 'id', with: 'asd'
    click_on I18n.t('main.chooser.participate.link')

    expect(page).to have_content I18n.t('main.controller.invalid_basket_id')
  end
end
