class Provider
  class InvalidProvider < StandardError; end

  PROVIDERS = {
    pizzade: {
      new_params:  { knddomain: 1, noflash: 1 },
      single_shop: false,
      domain:      'pizza.de',
      csp: <<-CSP.strip_heredoc
        img-src       'self'
        script-src    'self' 'unsafe-eval' 'unsafe-inline'
        style-src     'self' 'unsafe-eval' 'unsafe-inline' https://fonts.googleapis.com
        font-src      'self'  https://fonts.gstatic.com
      CSP
    },

    stadtsalatde: {
      single_shop: true,
      https:       true,
      domain:      'www.stadtsalat.de',
      defaults: {
        shop_name: 'Stadtsalat.de',
        shop_url:  '/hipster/provider_root',
      },
      passable_hosts: ['d2rzcb39z1r56i.cloudfront.net']
    }
  }.with_indifferent_access

  VALID_NAMES = PROVIDERS.keys

  def self.valid_name?(name)
    PROVIDERS.keys.include?(name)
  end

  def self.current(cookies)
    new(cookies['_hipsterpizza_mode'].to_s.split('_', 2).first)
  end

  def initialize(name)
    raise InvalidProvider unless Provider.valid_name?(name)
    @name = name
  end

  attr_reader :name

  def passable_host?(host)
    settings.fetch(:passable_hosts, []).include?(host)
  end

  def single_shop?
    settings[:single_shop]
  end

  def merge_defaults!(params)
    settings.fetch(:defaults, {}).each do |key, value|
      params[key] = value
    end
    params
  end

  def new_basket_url
    Rails.application.routes.url_helpers.root_service_path(name)
  end

  def new_parameters
    settings[:new_params] || {}
  end

  def domain
    settings[:domain]
  end

  def to_s
    @name
  end

  def csp
    settings.fetch(:csp, '').gsub("\n", ';').gsub(/\s+/, ' ')
  end

  private

  def settings
    PROVIDERS[name]
  end
end
