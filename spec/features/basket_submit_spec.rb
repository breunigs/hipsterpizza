# encoding: utf-8

require 'spec_helper'

describe 'BasketSubmit', type: :feature do
  it 'allows streaming' do
    visit url_for(controller: :basket_submit, action: :test, only_path: true)
    wait_until_content 'sentence is complete'
  end
end
