# encoding: utf-8

load_images = false
cache_requests = true



require 'capybara/rspec'
require 'capybara-screenshot/rspec'

Capybara.register_driver :webkit_no_imgs do |app|
  driver = Capybara::Webkit::Driver.new(app)
  driver.browser.set_skip_image_loading true
  driver
end

Capybara.register_driver :webkit_billy_no_imgs do |app|
  driver = Capybara::Webkit::Driver.new(app)
  driver.browser.set_proxy(:host => Billy.proxy.host,
                           :port => Billy.proxy.port)
  driver.browser.ignore_ssl_errors
  driver.browser.set_skip_image_loading true
  driver
end



driver = "webkit#{cache_requests ? "_billy" : ""}#{load_images ? "" : "_no_imgs"}"
driver = driver.to_sym

Capybara.current_driver = driver
Capybara.default_driver = driver
Capybara.javascript_driver = driver

Capybara.default_wait_time = ENV['CAPYBARA_WAIT'].to_i || 2
# teach capybara-screenshot about our custom drivers
Capybara::Screenshot.register_driver(driver)  do |driver, path|
  if driver.respond_to?(:save_screenshot)
    driver.save_screenshot(path)
  else
    driver.render(path)
  end
end

Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  desc = example.full_description
  "screenshot_#{desc.gsub(' ', '_')}"
end

Capybara::Screenshot.append_timestamp = false
