module ApplicationHelper
  include CookieHelper

  def euro(input)
    number_to_currency(input, unit: "€", format: "%n&thinsp;%u")
  end
end
