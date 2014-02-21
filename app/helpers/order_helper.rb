# encoding: utf-8

module OrderHelper
  def editing?
    cookie_get(:action).to_s == 'edit_order'
  end

  def new_order?
    cookie_get(:action).to_s == 'new_order'
  end

  def sum(pay = nil, pay_tip = nil)
    pay ||= @order.sum
    pay_tip ||= @order.sum_with_tip
    "#{euro(pay)} #{@basket.tips? ? "(or #{euro(pay_tip)} with tip)" : ''}"
  end
end
