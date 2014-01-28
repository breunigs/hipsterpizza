# encoding: utf-8

class MainController < ApplicationController
  include CookieHelper

  def chooser
    @basket = Basket.where(uid: cookie_get(:basket)).first
  end
end
