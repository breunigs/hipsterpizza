# encoding: utf-8

debug = false

require 'capybara/rspec'
require 'capybara-screenshot/rspec'

Capybara.register_driver :webkit_no_imgs do |app|
  driver = Capybara::Webkit::Driver.new(app)
  driver.browser.set_skip_image_loading true
  driver
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,
    phantomjs_logger: Rails.logger,
    inspector: true,
    timeout: 30
  )
end

Capybara.register_driver :poltergeist_no_debug do |app|
  Capybara::Poltergeist::Driver.new(app,
    phantomjs_options: [
      '--load-images=no',
      '--disk-cache=yes', # $HOME/.qws/cache/Ofi Labs/PhantomJS
    ],
    phantomjs_logger: Rails.logger
  )
end

driver = "poltergeist#{debug ? "" : "_no_debug"}"
driver = driver.to_sym
driver= :webkit_no_imgs
Capybara.current_driver = driver
Capybara.default_driver = driver
Capybara.javascript_driver = driver

Capybara.default_wait_time = ENV['CAPYBARA_WAIT'].try(:to_i) || 2

Capybara::Screenshot.register_driver(driver) do |driver, path|
  driver.save_screenshot(path)
end
Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  desc = example.full_description
  "screenshot_#{desc.gsub(' ', '_')}"
end

Capybara::Screenshot.append_timestamp = false
