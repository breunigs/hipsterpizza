# encoding: utf-8

require 'slim/translator'

Slim::Engine.set_default_options \
  tr: true, \
  tr_mode: Rails.env.production? ? :static : :dynamic
