pdf.font_size 11

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


pdf.move_down 15
pdf.text "Summe: #{euro_de(@basket.sum)}", size: 16, style: :bold


if @cfg['lat'] && @cfg['lon']
  vpos = pdf.cursor + 108

  lat = @cfg['lat']
  lon = @cfg['lon']

  osm = "http://www.osm.org/?mlat=#{lat}&mlon=#{lon}#map=17/#{lat}/#{@cfg['lon']}"
  gmaps = "https://maps.google.de/maps?q=#{lat},#{lon}&num=1&t=m&z=18"

  size = 100
  right = pdf.bounds.right
  pdf.print_qr_code(gmaps, extent: size, stroke: false, pos: [right-size+10, vpos])
  pdf.print_qr_code(osm, extent: size, stroke: false, pos: [right-2*size-39, vpos])
  pdf.text "Open Street Map#{' '*24}Google Maps#{Prawn::Text::NBSP*4}", align: :right
end

pdf.move_down 5



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


pdf.number_pages "Seite <page> von <total>", {at: [pdf.bounds.right - 150, 0], width: 150, align: :right }
