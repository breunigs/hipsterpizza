# encoding: utf-8

class MainController < ApplicationController
  include CookieHelper

  def chooser
    @basket = Basket.find_basket_for_single_mode
    return redirect_to_basket if @basket

    @basket = Basket.where(uid: cookie_get(:basket)).first
  end
end
