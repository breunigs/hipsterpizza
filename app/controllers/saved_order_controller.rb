# encoding: utf-8

class SavedOrderController < ApplicationController
  include CookieHelper

  before_filter :find_basket
  before_filter :find_order

  def index
    if params[:nick]
      cookie_set(:nick, params[:nick])
      # remove ?nick= from URL
      return redirect_to saved_order_index_path
    end
    @nick = cookie_get(:nick)
    @saved = SavedOrder.where(shop_url: @basket.shop_url).sorted
    @previous_orders = Order
      .joins(:basket)
      .where(nick: @nick, baskets: { shop_url: @basket.shop_url})
      .order('baskets.submitted DESC').limit(5)
  end

  def destroy
    return redirect_to saved_order_index_path unless @saved_order

    if @saved_order.destroy
      flash[:info] = "“#{@saved_order.name}” has been destroyed."
    else
      flash[:error] = "“#{@saved_order.name}” could not be destroyed. Ask the site administrator for help."
    end

    redirect_to saved_order_index_path
  end

  def copy
    cookie_set(:replay, "savedorder #{get_replay_mode} #{@saved_order.uuid}")
    cookie_set(:action, :new_order)
    redirect_to_shop
  end
end
