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

# silence capybara-screenshot’s warnings when using any of the
# customized drivers
Capybara::Screenshot.register_driver(:webkit_billy_no_imgs) {}
Capybara::Screenshot.register_driver(:webkit_no_imgs) {}

driver = "webkit#{cache_requests ? "_billy" : ""}#{load_images ? "" : "_no_imgs"}"
Capybara.current_driver = driver.to_sym
