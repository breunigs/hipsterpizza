class Provider
  class InvalidName < StandardError; end

  NEW_PARAMS = {
    "pizzade" => { knddomain: 1, noflash: 1 }
  }

  def self.valid_name?(name)
    ['pizzade', 'stadtsalatde'].include?(name.to_s)
  end

  def initialize(name)
    raise InvalidName unless Provider.valid_name?(name)
    @name = name
  end

  attr_reader :name

  def new_basket_url
    Rails.application.routes.url_helpers.root_service_path(name)
  end

  def new_parameters
    NEW_PARAMS[name] || {}
  end
end
