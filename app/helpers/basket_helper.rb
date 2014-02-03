module BasketHelper
  def admin?
    @basket && @basket.uid == cookie_get(:admin).to_s
  end

  def order_details(order)
    content_tag(:ul) do
      order.json_parsed.each do |item|
        ingred = item["extra"] * " + "
        ingred = ingred.empty? ? "" : " + #{ingred}"
        concat(content_tag(:li, "#{item["prod"]}#{ingred}"))
      end
    end
  end

  def time(t)
    s = t.strftime(t.today? ? '%H:%M' : '%Y-%m-%d %H:%M')
    s << ' ('
    happened = t < Time.now
    s << 'in ' unless happened
    s << distance_of_time_in_words_to_now(t)
    s << ' ago' if happened
    s << ')'
    s
  end
end
