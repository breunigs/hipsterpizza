# encoding: utf-8

# convenience hack function that encodes objects given into ISO-8859-1
# which is used by pizza.de.
def to_pizzade_encoding(obj)
  if obj.is_a?(String)
    obj = obj.encode("iso-8859-1")
  elsif obj.is_a?(Array)
    obj = obj.map { |x| x.encode("iso-8859-1") }
  end
  obj
end

# Inserts given string into page before the </head> element. The shop
# is determined by the BASE constant defined in config.ru
def inject(content)
  throw "inject only accepts strings!" unless content.is_a?(String)
  Net::HTTP::start("pizza.de") do |http|
    # ?knddomain=1 prevents the pizza.de sign in form and also gives
    # less provisions to pizza.de
    page = http.get(BASE + "/index.htm?knddomain=1").body
    page = page.force_encoding("ISO-8859-1").encode("UTF-8")
    scr = %(<script>hipsterPizzaHost = "#{OUR_HOST}";</script>)
    scr << %(<script type="text/javascript" src="#{OUR_HOST}/hipsterTools.js"></script>)
    scr << %(<link rel="stylesheet" type="text/css" href="#{OUR_HOST}/hipsterInject.css">)
    page.sub!("<script", %(#{scr}<script))
    page.sub!("</head>", content + "</head>")
    return page
  end
  return "Could not inject. Probably some error?"
end

# a HTTP redirect to the main page as expected by rackup.
def redirect_home
  # expected format: [status code, headers, content]
  [ 302, { "Content-Type" => "text/html", "Location" => OUR_HOST }, ["How did you get here?"] ]
end

# a HTTP redirect to the saved orders as expected by rackup.
def redirect_saved_orders
  [ 302, { "Content-Type" => "text/html", "Location" => OUR_HOST + "?action=showsaved" }, ["How did you get here?"] ]
end

def get_sum_for_order(tbl = nil)
  tbl = table_name if tbl.nil?

  # pro SQL injection prevention
  return nil unless tbl =~ /^[a-z0-9]+$/i
  begin
    sum = 0
    $db.execute("SELECT querystring FROM #{tbl}") do |row|
      JSON.parse(row["querystring"])['items'].each do |item|
        sum += item['price']
      end
    end
    return sum
  rescue
    return nil
  end
end

def get_delivery_time_for_order(tbl)
  begin
    cols, *times = $db.execute2("SELECT submitted, delivered FROM meta WHERE tblname = ?", tbl)
    s = Time.parse(times.first['submitted'])
    d = Time.parse(times.first['delivered'])
    return nil if (d-s) < 0
    return d-s
  rescue
    return nil
  end
end

# returns the amount of time required per euro on average for all orders
# with that data available.
def avg_delivery_time
  sums = 0
  times = 0
  cols, *rows = $db.execute2("SELECT tblname FROM meta")
  tbls = rows.map { |row| row['tblname'] }

  tbls.each do |tbl|
    s = get_sum_for_order(tbl)
    t = get_delivery_time_for_order(tbl)
    next if s.nil? || t.nil?
    sums += s
    times += t
  end

  return 0 if times == 0
  return times.to_f/sums.to_f
end


# fetches all items from the database and returns a JavaScript string
# that makes them available in “hipsterItems”. Also creates JS-variable
# “hipsterTotalPrice”.
def get_all_item_json
  items = []
  $db.execute("SELECT * FROM #{table_name}") do |row|
    order = JSON.parse(row["querystring"])
    items += order["items"]
  end

  sum = items.map { |i| i["price"] }.inject(0, :+)

  out = "var hipsterItems = #{JSON.generate(items)};"
  out << "var hipsterTotalPrice = #{'%.2f' % sum};"
  out
end

# finds the order as defined by ord_id and returns its items as Java-
# Script string. Second parameter should be the current date which is
# used to prevent accidental orders when dealing with browser history.
def get_item_json(ord_id, date)
  return nil unless date_is_valid?(date) && id_is_valid?(ord_id)

  cols, *rows = $db.execute2("SELECT * FROM #{table_name} WHERE id = ?", ord_id)
  return nil if rows.size == 0

  items = JSON.parse(rows[0]["querystring"])["items"]
  "var hipsterItems = #{JSON.generate(items)};"
end

# Retrieves stored order by name and returns its items as JavaScript
# string. Second parameter should be the current date which is used
# to prevent accidental orders when dealing with browser history.
def get_saved_item_json(name, date)
  return nil unless date_is_valid?(date)

  cols, *rows = $db.execute2("SELECT * FROM saved WHERE name = ?", name)
  return nil if rows.size == 0

  items = JSON.parse(rows[0]["querystring"])["items"]
  "var hipsterItems = #{JSON.generate(items)};"
end

# checks if the given date is valid -- i.e. if it is recent enough. It’s
# meant to prevent accidental orders when dealing with browser history.
def date_is_valid?(date)
  # near ridiculous security
  begin
    if (Date.parse(date) - Date.today).abs >= 2
      warn "Seems to be an old date."
      return false
    end
  rescue
    warn "Broken date."
    return false
  end
  true
end

# ensure the ord_id is numerical only.
def id_is_valid?(ord_id)
  return true if ord_id.match(/^[0-9]+$/)

  warn "Invalid ID: #{ord_id}"
  false
end

# extend Time class with “time_ago_in_words”. Originally copied from
# somewhere, but can’t remember where. If you know who to attribute,
# please let me know.
class Time
  module Units
    Second = 1
    Minute = Second * 60
    Hour = Minute * 60
    Day = Hour * 24
    Week = Day * 7
    Month = Week * 4
    Year = Day * 365
    Decade = Year * 10
    Century = Decade * 10
    Millennium = Century * 10
    Eon = 1.0/0
  end

  def time_ago_in_words
    time_difference = Time.now.to_i - self.to_i
    return "just now" if time_difference == 0

    is_future = time_difference < 0
    time_difference = time_difference.abs

    unit = get_unit(time_difference)
    unit_difference = time_difference / Units.const_get(unit.capitalize)

    puts time_difference
    puts unit

    unit = unit.to_s.downcase + (time_difference > 1 ? 's' : '')

    is_future \
      ? "in #{unit_difference} #{unit}" \
      : "#{unit_difference} #{unit} ago"
  end

  private
  def get_unit(time_difference)
    Units.constants.each_cons(2) do |con|
      return con.first if (Units.const_get(con[0])...Units.const_get(con[1])) === time_difference
    end
  end
end
