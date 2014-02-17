source 'https://rubygems.org'

gem 'rails', '4.0.2'
gem 'sqlite3'
gem 'sass-rails', '~> 4.0.0'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'slim'
gem 'therubyracer',         platform: :ruby
gem 'puma'
gem 'actionpack-action_caching'
gem 'rqrcode-rails3'
gem 'possessive'
gem 'unicode_utils'

gem 'mechanize', require: false
gem 'prawn'
gem 'prawn-qrcode'
gem 'prawn-rails', git: 'git://github.com/cortiz/prawn-rails.git'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'guard',              require: false
  gem 'guard-bundler',      require: false
  gem 'guard-rails',        require: false
  gem 'guard-shell',        require: false
  gem 'guard-rspec',        require: false
  gem 'guard-livereload',   require: false
  gem 'rack-livereload'
  gem 'quiet_assets'
  gem 'parallel_tests'
end

group :development, :test do
  gem 'rspec-rails'
end

group :test do
  gem 'simplecov',  require: false
  gem 'coveralls',  require: false
  gem 'capybara-webkit'
  gem 'capybara-screenshot', git: 'git://github.com/mattheworiordan/capybara-screenshot.git'
  gem 'puffing-billy', '>= 0.2.3'
end
