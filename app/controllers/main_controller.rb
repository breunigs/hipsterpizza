# encoding: utf-8

class MainController < ApplicationController
  def chooser
    @basket = Basket.where(uid: cookies['_hipsterpizza_basket']).first
  end
end
