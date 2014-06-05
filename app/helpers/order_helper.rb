# encoding: utf-8

module OrderHelper
  def sum(pay = nil, pay_tip = nil)
    pay ||= @order.sum
    pay_tip ||= @order.sum_with_tip
    "#{euro(pay)} #{tips? ? "(or #{euro(pay_tip)} with tip)" : ''}"
  end
end
