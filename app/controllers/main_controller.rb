# encoding: utf-8

class MainController < ApplicationController
  include CookieHelper

  def chooser
    if PINNING['single_basket_mode']
      # is there an editable basket we can forward the user to?
      @basket = Basket.find_editable
      return redirect_to_basket if @basket

      # is there a recently submitted basket in the timeout range?
      after = PINNING['single_basket_timeout'].minutes.ago
      @basket = Basket.find_recent_submitted(after)
      return redirect_to_basket if @basket
    end

    @basket = Basket.where(uid: cookie_get(:basket)).first
  end
end
