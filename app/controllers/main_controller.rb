# encoding: utf-8

class MainController < ApplicationController
  include CookieHelper

  before_action :find_basket

  def chooser
    b = Basket.find_basket_for_single_mode
    return redirect_to b if b
  end

  def find
    return redirect_to @basket if @basket

    flash[:error] = t 'main.controller.invalid_basket_id'
    render 'chooser'
  end

  def clock
    expires_in 1.day
    headers["Content-Type"] = "image/svg+xml"
    render 'clock.svg', layout: false
  end

  def set_nick
    cookie_set(:nick, params[:nick])
    target = request.referer || @basket || root_path
    logger.warn target

    redirect_to target
  end
end
