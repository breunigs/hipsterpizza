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

  def contact_details_array
    def get(field)
      @cfg['address'][field.to_s] || PINNING['address'][field.to_s]
    end

    def add!(arr, desc, *lines)
      lines.each do |line|
        next if line.blank?
        arr << [desc, line.strip]
        desc = ''
      end
    end

    data = []
    add!(data, 'Firma',     get(:company)   + ' ' + get(:department))
    add!(data, 'Empfänger', get(:firstname) + ' ' + get(:lastname),
                            get(:street)    + ' ' + get(:street_no),
                            get(:zipcode)   + ' ' + get(:city))
    phone = get(:areacode).to_s + get(:local_number).to_s
    add!(data, 'Telefon',   phone.scan(/.{1,4}/).join(' '))
    add!(data, 'E-Mail',    get(:email))
    if get(:details)
      data << ['Bemerkung', '']
      data << [{content: get(:details), colspan: 2}]
    end
  end

  def order_details_array
    o = [[
      "Produkt",
      {content: "Preis (€)", align: :right},
      {content: "Beschriftung", align: :right}
    ]]

    space = "\n#{Prawn::Text::NBSP*4} + "
    @basket.orders.each do |order|
      j = order.json_parsed
      j.each do |item|
        prod = item["prod"]
        prod << space + item["extra"] * space if item["extra"].any?

        price = number_to_currency(item["price"], unit: "", separator: ',')
        o << [
          prod,
          {content: price, align: :right},
          {content: order.nick_id, align: :right},
        ]
      end
    end
    o
  end
end
