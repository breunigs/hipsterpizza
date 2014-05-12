# encoding: utf-8

class MainController < ApplicationController
  include CookieHelper

  def chooser
    @basket = Basket.find_basket_for_single_mode
    return redirect_to_basket if @basket

    @basket = Basket.where(uid: cookie_get(:basket)).first
  end

  def clock
    expires_in 1.day
    headers["Content-Type"] = "image/svg+xml"
    render 'clock.svg', layout: false
  end
end
