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
    @order ? I18n.t('basket.new_order_button.existing_order') : ''
  end

  def has_nick?
    cookie_get(:nick).present?
  end

  def tips?
    CONFIG['tip_percent'].present? && CONFIG['tip_percent'] > 0
  end

  def nick_ids?
    CONFIG['show_nick_ids'].present? && !!CONFIG['show_nick_ids']
  end

  def show_insta_order?
    # insta mode requires nick for streamlined copying. If there’s already an
    # order for that nick, there’ll be two orders with the same nick. There’s no
    # way to choose which of those is “my order”, requiring admin rights for
    # proper handling. Thus, avoid it.
    has_nick? && @order.nil?
  end

  def admin?
    cookie_get(:is_admin).to_s == 'true'
  end

  def my_order?
    n = cookie_get(:nick).to_s
    return false if @order.nil? || n.blank?
    n == @order.nick
  end
end
