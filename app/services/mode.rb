class Mode
  include ActionController::Helpers
  include ActionController::Cookies

  class InvalidMode < StandardError; end

  VALID_MODES = %w(
    basket_new
    basket_submit
    order_new
    order_edit
  ).freeze

  def self.current(cookies)
    mode = cookies['_hipsterpizza_mode'].to_s.split('_', 2)
    raise InvalidMode unless VALID_MODES.include?(mode[1])

    new(mode[1])
  end

  def initialize(mode)
    @mode = mode
  end

  def requires_basket?
    @mode != 'basket_new'
  end

  def to_s
    @mode
  end
end
