# encoding: utf-8

module ApplicationHelper
  include CookieHelper

  def euro(input)
    number_to_currency(input, unit: "€", format: "%n%u", delimiter: ' ')
  end

  def euro_de(input)
    number_to_currency(input, unit: "€", format: "%n%u", delimiter: ' ', separator: ',')
  end

  def overwrite_order_confirm
    @order ? 'There’s already an order for you. Continue only if this is for someone else (=OK), otherwise edit your old order (=Cancel).' : ''
  end

  def auto_basket_path
    @basket ? basket_with_uid_path(@basket.uid) : basket_path
  end

  def has_nick?
    !cookie_get(:nick).blank?
  end

  def tips?
    defined?(CONFIG['tip_percent']) && CONFIG['tip_percent'] > 0
  end
end
