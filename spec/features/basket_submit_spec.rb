# encoding: utf-8

require 'spec_helper'

def is_puffing_billy?
  Capybara.current_driver.to_s.include?('_billy')
end

describe 'BasketSubmit' do
  before do
    page.driver.browser.clear_proxy if is_puffing_billy?
  end

  after do
    page.driver.browser.set_proxy(host: Billy.proxy.host, port: Billy.proxy.port) if is_puffing_billy?
  end

  it 'allows streaming' do
    visit url_for(controller: :basket_submit, action: :test, only_path: true)
    wait_until_content 'sentence is complete'
  end
end
