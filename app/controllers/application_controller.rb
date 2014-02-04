# encoding: utf-8

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


  def find_basket
    uid = params[:basket_uid]
    uid ||= cookie_get(:basket)
    @basket = Basket.where(uid: uid).first

    # ensure cookies and URL match up
    cookie_set(:basket, @basket ? @basket.uid : nil)

    # handle failure
    unless @basket
      flash[:error] = uid ? 'Invalid Basket-ID. Are you sure there are no typos and that it is recent?' : 'Missing Basket-ID. Ask someone to share the link with you or create initiate a new group order.'
      redirect_to root_path(uid: uid)
    end
  end

  def find_order
    uuid = params[:order_uuid]
    uuid ||= cookie_get(:order)
    @order = Order.where(uuid: uuid, basket: @basket).first
  end

  def redirect_to_basket
    redirect_to basket_with_uid_path(@basket.uid)
  end

  def redirect_to_shop
    # knddomain=1 hides pizza.de related branding and logins
    # noredir=1 prevents the “switch to mobile?” popup
    redirect_to @basket.shop_url + '?knddomain=1&noredir=1'
  end

  def redirect_to_pizzade
    # noredir=1 prevents the “switch to mobile?” popup
    redirect_to pizzade_root_path + '?noredir=1'
  end

  def get_replay_mode
    modes = ['insta', 'nocheck', 'check']
    p = params[:mode]
    return p if modes.include?(p)
    logger.warn "Invalid Replay Mode: #{p}" unless p.blank?
    modes.last
  end

  def reset_replay
    cookie_delete(:replay)
  end
end
