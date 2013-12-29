# encoding: utf-8

class Order < ActiveRecord::Base
  attr_accessible :nick, :json_blob, :paid

  belongs_to :basket
end
