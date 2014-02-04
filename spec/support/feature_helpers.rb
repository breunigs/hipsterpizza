# encoding: utf-8

module FeatureHelpers
  def basket_with_order_create
    basket_create
    visit basket_path
    order_create
  end

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

  def order_create
    click_on 'Place New Order'
    click_on 'Chicken Curry', match: :first

    accept_nick!

    click_on 'Place My Order in Group Basket'

    expect(page).to have_content 'You still need to pay'
    expect(page).to have_content 'Chicken Curry'
    expect(page).to have_content 'Tėst Ñiçk 1_2-3'
  end

  def accept_nick!
    page.driver.js_prompt_input = "Tėst Ñiçk 1_2-3"
    page.driver.accept_js_prompts!
  end

  def reload
    visit(current_url)
  end

  def shot(name)
    save_screenshot("tmp/capybara/manual_screenshot_#{name}.png")
  end

  def print_console_msgs
    page.driver.console_messages.each { |m| puts m[:message] }
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
