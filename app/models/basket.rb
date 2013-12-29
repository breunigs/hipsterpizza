# encoding: utf-8

class Basket < ActiveRecord::Base
  attr_accssible :store_name, :submitted
  validates :store_name, presence: true

  has_many :orders
end
