# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150315090547) do

  create_table "baskets", force: :cascade do |t|
    t.string   "shop_name",       limit: 255
    t.datetime "submitted"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "shop_url",        limit: 255
    t.string   "uid",             limit: 255
    t.boolean  "cancelled",                   default: false
    t.string   "sha_address",     limit: 255
    t.datetime "arrival"
    t.string   "shop_fax",        limit: 255
    t.string   "shop_url_params", limit: 255
    t.string   "provider"
  end

  create_table "orders", force: :cascade do |t|
    t.string   "nick",       limit: 255
    t.string   "json",       limit: 255
    t.string   "uuid",       limit: 255
    t.integer  "basket_id"
    t.boolean  "paid",                   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "saved_orders", force: :cascade do |t|
    t.string "shop_url", limit: 255
    t.string "nick",     limit: 255
    t.string "json",     limit: 255
    t.string "name",     limit: 255
    t.string "uuid",     limit: 255
  end

end
