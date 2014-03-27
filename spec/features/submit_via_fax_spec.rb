# encoding: utf-8

require 'spec_helper'
require 'pp'

describe 'Submitting with provider' do
  fax_config = {}

  before do
    allow_any_instance_of(BasketSubmitController).to \
      receive(:load_fax_config) { fax_config }

    fax_config = { 'order_by_fax' => true }
    basket_with_order_create
  end


  context '“manual”' do
    before do
      fax_config['fax_provider'] = 'manual'
    end

    it 'redirects to PDF on submit' do
      visit basket_path
      click_on 'Submit Group Order', match: :first
      wait_until_content '%PDF-1.3'
      expect(current_url).to end_with '/pdf'
    end
  end

  context '“PDF24.org”' do
    before do
      fax_config['fax_provider'] = 'pdf24'
      fax_config['pdf24_mail'] = 'fake'
      fax_config['pdf24_pass'] = 'fake'
    end

    it 'tries to submit via PDF24' do
      visit basket_path
      click_on 'Submit Group Order', match: :first
      wait_until_content 'Loading landing page'
      wait_until_content 'Uploading PDF'
      wait_until_content 'Logging In'
      expect(page).to have_content 'Return To Basket'
    end
  end
end
