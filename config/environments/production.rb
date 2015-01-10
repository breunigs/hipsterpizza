Hipsterpizza::Application.configure do
  # HipsterPizza note: Usually static files should be served by a reverse proxy in front
  # of HipsterPizza, e.g. Apache or nginx. Since HipsterPizza is likely low traffic, this
  # performance impact can be ignored. The idea is to make setup easier for Rails novices
  # just trying to run HipsterPizza locally.
  config.serve_static_files = true

  config.cache_classes = true
  config.eager_load = true

  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.assets.compress = true
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass
  config.assets.compile = false
  config.assets.digest = true
  config.assets.precompile += %w( ours.js pizzade.js inject_pizzade.css sha512.js ours.css pizzade.css )
  config.assets.version = '1.0'

  config.log_level = :info
  config.log_formatter = ::Logger::Formatter.new

  config.i18n.fallbacks = true

  config.active_support.deprecation = :notify

  config.cache_store = :memory_store, { size: 128*1024*1024 }
end
