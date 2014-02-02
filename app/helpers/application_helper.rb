# encoding: utf-8

module ApplicationHelper
  include CookieHelper

  def euro(input)
    number_to_currency(input, unit: "€", format: "%n%u")
  end
end
