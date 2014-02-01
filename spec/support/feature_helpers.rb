# encoding: utf-8

module FeatureHelpers
  def basket_create
    visit root_path
    click_link 'Create New Basket'

    fill_in 'plzsearch_input', with: '12347'
    has_content?('12347 Berlin')

    click_link 'Lieferservice suchen'
    click_link 'Indian Curry'

    within('#hipsterTopBar') do
      click_on 'Choose Indian Curry'
    end
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
