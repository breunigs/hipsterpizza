# encoding: utf-8

module BasketHelper
  def update_via_js(selector, template)
    js = escape_javascript(render *template) unless template.nil?
    %($('#{selector}').html("#{js}")\n).html_safe
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
    return t.strftime('%Y-%m-%d %H:%M') unless t > 12.hours.ago

    timestamp = content_tag(:time, t.strftime('%H:%M'), datetime: t)

    key = t < Time.now ? 'past' : 'future'
    relative = t('time.' + key, date: time_ago_in_words(t))
    ago = content_tag(:span, relative, class: 'text-muted')

    timestamp << ago
  end

  def contact_field(field)
    x = @cfg['address'][field.to_s] rescue nil
    x ||= PINNING['address'][field.to_s] rescue nil
    x
  end

  def contact_sha_address
    addr = ''
    addr << contact_field(:zipcode) << ' '
    addr << contact_field(:street) << ' '
    addr << contact_field(:street_no) << ' '
    addr.strip.downcase.gsub(/[^a-z0-9]/, '')
  end

  def contact_details_array
    def get(f)
      contact_field(f) || ''
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
    add!(data, 'Erstellt',  Time.now.strftime("%H:%M Uhr %d.%m.%Y"))
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
    @basket.orders.sorted.each do |order|
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
