if @cfg['logo']
  pdf.image @cfg['logo'], position: :right, width: 200, at: [pdf.bounds.right-200, pdf.bounds.top]
end

d = contact_details_array
pdf.table(d, column_widths: { 0 => 80 }) do
  cells.padding = 1
  cells.borders = []
  columns(0).font_style = :bold
  d.each.with_index do |dd, i|
    # hack to avoid making the order details bold as well
    next unless dd.first.is_a?(Hash) && dd.first[:colspan] > 1
    row(i).font_style = :normal
  end
end



pdf.move_down 20



o = order_details_array
last = o.size - 1
pdf.table(o, column_widths: [380, 65, 90], header: true) do
  cells.padding = 8
  cells.borders = []
  row(0..last).borders = [:top]
  row(0).border_width = 2

  row(last-1).borders = [:top, :bottom]

  row(last).border_width = 2
  row(last).borders = [:bottom]

  row(0).font_style = :bold
end




below_table = pdf.cursor - 10
pdf.move_down 20
pdf.text "Summe: #{euro_de(@basket.sum)}", size: 20, style: :bold

pdf.move_down 10
pdf.text "Erstellt: #{Time.now.strftime("%H:%M Uhr %d.%m.%Y")}"

if @cfg['lat'] && @cfg['lon']
  lat = @cfg['lat']
  lon = @cfg['lon']

  osm = "http://www.osm.org/?mlat=#{lat}&mlon=#{lon}#map=17/#{lat}/#{@cfg['lon']}"
  gmaps = "https://maps.google.de/maps?q=#{lat},#{lon}&num=1&t=m&z=18"

  size = 100
  right = pdf.bounds.right
  pdf.print_qr_code(gmaps, extent: size, stroke: false, pos: [right-size+10, below_table])
  pdf.print_qr_code(osm, extent: size, stroke: false, pos: [right-2*size-70, below_table])
  pdf.text "Open Street Map#{' '*29}Google Maps#{Prawn::Text::NBSP*3}", align: :right
end




pdf.number_pages "Seite <page> von <total>", {at: [pdf.bounds.right - 150, 0], width: 150, align: :right }
