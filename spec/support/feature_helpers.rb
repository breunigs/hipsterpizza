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

    expect(page).to have_content('Pizza Lieferservice und Pizzaservice')

    fill_in 'plzsearch_input', with: '12347'
    expect(page).to have_content('12347 Berlin')

    first('.suggest_entry_active, .suggest_entry').click
    expect(page).to have_content('pizza.de-Bewertungen in PLZ 12347 Britz')
    click_link 'Indian Curry'

    # wait for page load, reduce breakage
    expect(page).to have_content('Warenkorb')
    within('#hipsterTopBar') do
      click_on 'Choose Indian Curry'
    end

    expect(page).to have_content('Share Link')
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
    path = "tmp/capybara/manual_screenshot_#{name}.png"
    save_screenshot(path)
    puts
    puts "IMAGE = #{path}"
    puts "URL   = #{Capybara.current_url}"
    puts
  end

  def print_console_msgs
    page.driver.console_messages.each { |m| puts m[:message] }
  end

  def visit_basket_as_new_user
    visit basket_path
    url = Capybara.current_url
    Capybara.reset_sessions!
    visit url
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
