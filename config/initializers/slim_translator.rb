require 'slim/translator'

Slim::Engine.set_options \
  tr: true, \
  tr_mode: Rails.env.production? ? :static : :dynamic
