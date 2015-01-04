module FeatureHelpers
  TEST_NICK = 'Tėst Ñiçk 1_2-3'

  def shot(name)
    path = "tmp/capybara/manual_screenshot_#{name}.png"
    save_screenshot(path)
    puts
    puts "IMAGE = #{path}"
    puts "URL   = #{Capybara.current_url}"
    puts
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
