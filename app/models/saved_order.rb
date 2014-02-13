# encoding: utf-8

class SavedOrder < ActiveRecord::Base
  validates :json, presence: true, json: true
  validates :nick, presence: true
  validates :shop_url, presence: true,
    format: { with: %r{\A/}, message: "must start with /" }


  def self.exists?(nick, order)
    SavedOrder.where(nick: nick, json: order.json, shop_url: order.basket.shop_url).exists?
  end
end
