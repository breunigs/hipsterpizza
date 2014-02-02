# encoding: utf-8

module OrderHelper
  def editing?
    cookie_get(:action).to_s == 'edit_order'
  end

  def new_order?
    cookie_get(:action).to_s == 'new_order'
  end

  def amount(pay = nil, pay_tip = nil)
    pay ||= @order.amount
    pay_tip ||= @order.amount_with_tip
    "#{euro(pay)} (or #{euro(pay_tip)} with tip)"
  end
end
