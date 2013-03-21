#!/usr/bin/env ruby
# encoding: utf-8

require "sqlite3"
require "json"
require "pp"

DB_FILE = File.dirname(__FILE__) + "/db.sqlite3"
$db = SQLite3::Database.new(DB_FILE)
$db.results_as_hash = true

cols, *rows = $db.execute2("SELECT tblname FROM meta")

tbls = rows.map { |row| row['tblname'] }
# pro SQL injection prevention
tbls.reject! { |tbl| !tbl =~ /^a-z0-9$/i }

sums = {}
total = 0
tbls.each do |tbl|
  cols, *qss = $db.execute2("SELECT querystring FROM #{tbl}")
  sums[tbl] = 0
  qss.each do |qs|
    JSON.parse(qs['querystring'])['items'].each do |item|
      sums[tbl] += item['price']
      total += item['price']
    end
  end
end

sums.reject! { |k, v| v == 0 }
puts "Order".ljust(20) + " Sum".rjust(8)
sums.each { |k, v| puts k.ljust(20) + (" %.2f" % v).rjust(8) }

puts "\nAVG for all orders:"
puts ("%.2f" % (total/sums.size.to_f))
