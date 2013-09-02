#!/usr/bin/env ruby
# encoding: utf-8

require "pp"
require "date"
require "time"
require "sqlite3"
require "net/http"
require "json"

require "./tools.rb"
require "./db.rb"


cols, *rows = $db.execute2("SELECT tblname FROM meta")
tbls = rows.map { |row| row['tblname'] }

puts "price time"
tbls.each do |tbl|
  s = get_sum_for_order(tbl)
  t = get_delivery_time_for_order(tbl)
  next if s.nil? || t.nil?
  puts "#{s} #{t}"
end

