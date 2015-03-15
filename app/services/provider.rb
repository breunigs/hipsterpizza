class Provider
  class InvalidProvider < StandardError; end

  NEW_PARAMS = {
    "pizzade" => { knddomain: 1, noflash: 1 }
  }

  VALID_NAMES = ['pizzade', 'stadtsalatde']

  def self.valid_name?(name)
    VALID_NAMES.include?(name.to_s)
  end

  def self.current(cookies)
    new(cookies['_hipsterpizza_mode'].to_s.split('_', 2).first)
  end

  def initialize(name)
    raise InvalidProvider unless Provider.valid_name?(name)
    @name = name
  end

  attr_reader :name

  def new_basket_url
    Rails.application.routes.url_helpers.root_service_path(name)
  end

  def new_parameters
    NEW_PARAMS[name] || {}
  end

  def to_s
    @name
  end
end
