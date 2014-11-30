# encoding: utf-8

require 'spec_helper'
require 'pp'

xdescribe 'Submitting with provider', type: :feature do
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
      visit basket_path(@basket)
      open_admin_menu(I18n.t('button.submit_group_order.first_time.text'))

      expect(page.response_headers).to include('Content-Type' => 'application/pdf')
      # TODO: Poltergeist appears to download the PDF instead and does not
      # update the body. Therefore, the old content is still visible.
      # wait_until_content '%PDF-1.3'
      # expect(current_url).to end_with '/pdf'
    end
  end

  context '“PDF24.org”' do
    before do
      fax_config['fax_provider'] = 'pdf24'
      fax_config['pdf24_mail'] = 'fake'
      fax_config['pdf24_pass'] = 'fake'
    end

    it 'tries to submit via PDF24' do
      visit basket_path(@basket)
      open_admin_menu(I18n.t('button.submit_group_order.first_time.text'))
      wait_until_content 'Loading landing page'
      wait_until_content 'Uploading PDF'
      wait_until_content 'Logging In'
      expect(page).to have_content 'Return To Basket'
    end
  end
end
