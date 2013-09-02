# encoding: utf-8

# the absolute URL where the page will be available from the outside
OUR_HOST = "http://YOUR.PUBLIC.URL"

# in which page should stuff be injected
BASE = "/order/PIZZA_SERVICE_NAME_HERE/01"

# limit to one weekday or allow any time order
ONLY_ON = nil
#ONLY_ON = "thursday"


# Run with: rackup -s thin
# then browse to http://localhost:9292
# Or with: thin start -R config.ru
# then browse to http://localhost:3000
#
# Check Rack::Builder doc for more details on this file format:
# http://rack.rubyforge.org/doc/classes/Rack/Builder.html

require "pp"
require "date"
require "time"
require "sqlite3"
require "net/http"
require "json"


LOCAL_FILES = {
  "/bootstrap.min.css" =>
    ["text/css", File.open("bootstrap.min.css", "rb").read],

  "/turbolinks.js" =>
    ["text/javascript", File.open("turbolinks.js", "rb").read],

  "/gui-nick-handler.js" =>
    ["text/javascript", File.open("gui-nick-handler.js", "rb").read],

  "/0_image/pizza-de_logoshop_v8.gif" =>
    ["image/png", File.open("images/logosml.png", "rb").read],

  "/images/logo.png" =>
    ["image/png", File.open("images/logo.png", "rb").read],

  "/hipsterTools.js" =>
    ["text/javascript", File.open("tools.js", "rb").read],

  "/hipsterInject.css" =>
    ["text/css", File.open("inject.css", "rb").read],

  "/hipsterDeliveryData.json" =>
    ["text/javascript", File.open("hipsterDeliveryData.json", "rb").read]
}

DELIVERY_DATA = JSON.parse(LOCAL_FILES["/hipsterDeliveryData.json"][1])

# Read inject data once
INJECT_NEW_ORDER = File.open("inject-new-order.html", "rb:UTF-8").read
INJECT_ADMIN = File.open("inject-admin.html", "rb:UTF-8").read

# these will fail if there are invalid bytes in the files
INJECT_NEW_ORDER.sub("utf8 test", "")
INJECT_ADMIN.sub("utf8 test", "")

require "./tools.rb"
require "./cache.rb"
require "./reverse_proxy.rb"
require "./db.rb"
require "./gui.rb"
require "./pdf.rb"

module Rack
  class DeflaterWithInclusions < Deflater
    def initialize(app, options = {})
      @app = app
    end

    def call(env)
      unless LOCAL_FILES.keys.include?(env['PATH_INFO'])
        @app.call(env) # i.e. don’t gzip
      else
        super(env) # i.e. gzip
      end
    end
  end
end

use Rack::DeflaterWithInclusions


use Rack::ReverseProxy do
  # not sure why I set it false before. It needs to be true now.
  reverse_proxy_options :preserve_host => true

  # matching in reverse proxy has been overwritten to ignore
  # "/" and all LOCAL_FILES.
  reverse_proxy "/", "http://pizza.de#{BASE}"
end

app = proc do |env|
  out = []
  req = Rack::Request.new(env)


  if req.path == "/"
    p = req.params
    # who needs proper encoding anyway?
    p.each do |k, v|
      p[k] = v.force_encoding("ISO-8859-1").encode("UTF-8") if v.is_a?(String)
    end
    case p["action"]
      when "genpdf" then
        [ 200, { "Content-Type" => "application/pdf" }, [pdf_generate]]

      when "neworder" then
        page = inject(INJECT_NEW_ORDER)

        # load pizza category by default instead of mexican food
        page.sub!("cart.initCart( '/order/eppelheim_pizza-rapido/01/', 'framek080.htm'", "cart.initCart( '/order/eppelheim_pizza-rapido/01/', 'framek010.htm'")

        out << page
        [ 200, { "Content-Type" => "text/html" }, to_pizzade_encoding(out) ]

      when "copy" then
        scr = get_item_json(p["id"], p["date"])
        unless scr.nil?
          page = inject(INJECT_NEW_ORDER)
          page.sub!("<script", "<script>#{scr}</script><script")
          out << to_pizzade_encoding(page)
        else
          out += [html_header, "Order could not be copied.", html_footer]
        end
        [ 200, { "Content-Type" => "text/html" }, out ]

      when "ordersaved" then
        scr = get_saved_item_json(p["name"], p["date"])
        unless scr.nil?
          page = inject(INJECT_NEW_ORDER)
          page.sub!("<script", "<script>#{scr}</script><script")
          out << to_pizzade_encoding(page)
        else
          msg = %(<br/>Saved order could not be retrieved. Maybe you used an old link? )
          msg << %(<a href="?action=showsaved">Visit the saved order page and try again.</a>)
          out += [html_header, msg, html_footer]
        end
        [ 200, { "Content-Type" => "text/html" }, out ]

      when "edit" then
        scr = get_item_json(p["id"], p["date"])
        unless scr.nil?
          page = inject(INJECT_NEW_ORDER)
          page.sub!("<script", "<script>#{scr} var hipsterDeleteOldOrder = #{p["id"]};</script><script")
          out << to_pizzade_encoding(page)
        else
          out += [html_header, "Order could not be edited.", html_footer]
        end
        [ 200, { "Content-Type" => "text/html" }, out ]


      when "submit" then
        order_mark_submitted # prevent further orders
        page = inject(INJECT_ADMIN)
        page.sub!("<script", "<script>#{get_all_item_json};</script><script")
        out << to_pizzade_encoding(page)
        [ 200, { "Content-Type" => "text/html" }, out ]

      when "add" then
        worked, content = add_order_from_query_string(p["order"])
        if worked
          remove_order_by_id(p["delete"], p["date"]) if p["delete"]
          redirect_home
        else
          puts "Oh noez, something went wrong!"
          puts content
          out += [html_header, content, html_footer]
          [ 200, { "Content-Type" => "text/html" }, out ]
        end

      when "delete" then
        worked, content = remove_order_by_id(p["id"], p["date"])
        if worked
          redirect_home
        else
          puts "Oh noez, something went wrong!"
          puts content
          out += [html_header, content, html_footer]
          [ 200, { "Content-Type" => "text/html" }, out ]
        end

      when "togglepaid" then
        worked, content = toggle_paid(p["id"], p["date"])
        if worked
          redirect_home
        else
          puts "Oh noez, something went wrong!"
          puts content
          out += [html_header, content, html_footer]
          [ 200, { "Content-Type" => "text/html" }, out ]
        end

      when "marksubmitted" then
        order_mark_submitted
        redirect_home

      when "markdelivered" then
        order_mark_delivered
        redirect_home

      when "saveorder" then
        worked, content = save_order(p["id"], p["name"])
        if worked
          redirect_saved_orders
        else
          puts "Oh noez, something went wrong!"
          puts content
          out += [html_header, content, html_footer]
          [ 200, { "Content-Type" => "text/html" }, out ]
        end

      when "deletesaved" then
        delete_saved_order(p["name"], p["date"])
        redirect_saved_orders

      when "showsaved" then
        out << html_header
        out << user_actions
        out << saved_orders_table
        out << html_footer
        # XHR-Header is required turbolinks updates the current URL for
        # pages that redirect here.
        [ 200, { "Content-Type" => "text/html", "X-XHR-Current-Location" => OUR_HOST + "?action=showsaved" }, out ]

      else
        out << html_header
        out << user_actions
        out << overview_table
        out << money_stats
        out << order_status
        out << html_footer
        # XHR-Header is required turbolinks updates the current URL for
        # pages that redirect here.
        [ 200, { "Content-Type" => "text/html", "X-XHR-Current-Location" => OUR_HOST }, out ]
    end

  elsif LOCAL_FILES.keys.include?(req.path)
    h = LOCAL_FILES[req.path]
    [ 200, { "Content-Type" => h[0], "Cache-Control" => "max-age=#{6*24*60*60}, public" }, [h[1]]]
  else
    throw("Should never get here, should be handled by reverse proxy.")
  end
end

run app
