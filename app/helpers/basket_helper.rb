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
end
