# encoding: utf-8

class SavedOrderController < ApplicationController
  include CookieHelper

  before_action :require_basket
  before_action :require_saved_order, except: :index

  def index
    @nick = cookie_get(:nick)
    @saved = SavedOrder.where(shop_url: @basket.shop_url).sorted
    @previous_orders = Order
      .joins(:basket)
      .where(nick: @nick, baskets: { shop_url: @basket.shop_url })
      .order('baskets.submitted DESC').limit(5)
  end

  def destroy
    name = @saved_order.name

    if @saved_order.destroy
      flash[:info] = I18n.t('saved_order.model.destroyed', name: name)
    else
      flash[:error] = I18n.t('saved_order.model.destroy_failed', name: name)
    end

    redirect_to saved_order_index_path
  end

  def copy
    cookie_set(:replay, "savedorder #{replay_mode} #{@saved_order.uuid}")
    cookie_set(:mode, :pizzade_order_new)
    redirect_to_shop
  end

  private

  def require_saved_order
    @saved_order = SavedOrder.friendly.find(params[:saved_order_id])
    redirect_to saved_order_index_path unless @saved_order
  end
end
