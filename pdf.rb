# encoding: utf-8

require "rubygems"
require "prawn"
require "json"

def pdfheader
  image "images/faxlogo.png", position: :right, width: 200, at: [bounds.right-200, bounds.top]

  data = [
    ["Firma", DELIVERY_DATA["firma"]],
    ["Empfänger", DELIVERY_DATA["vorname"] + " " + DELIVERY_DATA["nachname"]],
    ["", DELIVERY_DATA["strasse"] + " " + DELIVERY_DATA["housenumber"]],
    ["", DELIVERY_DATA["plz"] + " " + DELIVERY_DATA["ort"]],
    ["Telefon", DELIVERY_DATA["vorwahl"] + " " + DELIVERY_DATA["telefon"]],
    ["E-Mail", DELIVERY_DATA["mail"]],
    ["Bemerkung", ""],
    [{content: DELIVERY_DATA["bemerkung"], :colspan => 2}]
  ]

  table(data, column_widths: { 0 => 80 }) do
    cells.padding = 1
    cells.borders = []
    columns(0).font_style = :bold
    row(7).font_style = :normal
  end

  move_down 20
end

def pdffooter
  move_down 30
  size = 120
  image "images/map_google.png", position: :left, width: size
  move_up size
  image "images/map_osm.png", position: :right, width: size
  move_up size/2
  text "Google Maps                               Open Street Map", align: :center
end

def pdf_generate
  unless table_exists?
    doc = Prawn::Document.new(page_size: "A4") do
      pdfheader
      text "Keine Bestellungen"
      pdffooter
    end
    return doc.render
  end

  data = [[
    "Produkt",
    {content: "Preis (€)", align: :right},
    {content: "Beschriftung", align: :right}
  ]]

  sum = 0
  $db.execute("SELECT * FROM #{table_name} ORDER BY nick COLLATE NOCASE ASC") do |row|
    order = JSON.parse(row["querystring"])
    sum += order["items"].map { |i| i["price"].to_f }.inject(0, :+)

    order["items"].map do |item|
      space = "\n#{Prawn::Text::NBSP*4} + "

      prod = item["prod"]
      prod << space + item["extra"] * space unless item["extra"].empty?

      price = ('%.2f' % item["price"]).sub(".", ",")

      data << [
        prod,
        {content: price, align: :right},
        {content: row["nick"][0..2].upcase, align: :right},
      ]
    end
  end


  doc = Prawn::Document.new(page_size: "A4") do
    pdfheader

    last = data.size - 1

    table(data, column_widths: {1 => 60, 2 => 90}) do
      cells.padding = 8
      cells.borders = []
#~　columns(0..1).borders = [:right]
      row(0..last).borders = [:top]
      row(0).border_width = 2

      row(last-1).borders = [:top, :bottom]

      row(last).border_width = 2
      row(last).borders = [:bottom]

      row(0).font_style = :bold

    end

    move_down 20
    text "Summe: #{('%.2f' % sum).sub(".", ",")} €", size: 20, style: :bold

    move_down 10
    text "Erstellt: #{Time.now.strftime("%H:%M Uhr %d.%m.%Y")}"

    pdffooter

    number_pages "Seite <page> von <total>", {at: [bounds.right - 150, 0], width: 150, align: :right }
  end

  return doc.render
end
