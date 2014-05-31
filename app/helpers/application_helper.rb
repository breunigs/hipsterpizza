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

  def has_nick?
    !cookie_get(:nick).blank?
  end

  def tips?
    defined?(CONFIG['tip_percent']) && CONFIG['tip_percent'] > 0
  end

  def nick_ids?
    defined?(CONFIG['show_nick_ids']) && CONFIG['show_nick_ids']
  end

  def show_insta_order?
    # insta mode requires nick for streamlined copying. If there’s already an
    # order for that nick, there’ll be two orders with the same nick. There’s no
    # way to choose which of those is “my order”, requiring admin rights for
    # proper handling. Thus, avoid it.
    has_nick? && @order.nil?
  end
end
