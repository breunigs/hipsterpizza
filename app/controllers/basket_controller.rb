# encoding: utf-8

class BasketController < ApplicationController
  include CookieHelper

  before_filter :find_basket, except: [:new, :create]
  before_filter :find_order, only: [:show]

  def new
    cookie_set(:action, :choose_shop)
    cookie_delete(:basket)
    cookie_delete(:admin)

    redirect_to pizzade_root_path
  end

  def create
    b = Basket.create(params.permit(:shop_name, :shop_url))
    if b.errors.any?
      msgs = "\n• " + b.errors.full_messages.join("\n• ")
      render text: "Could not create basket. Messages: #{msgs}"
      # TODO: nicer rendering
    else
      cookie_set(:action, :share_link)
      cookie_set(:basket, b.uid)
      cookie_set(:admin, b.uid)

      redirect_to share_basket_path(b.uid)
    end
  end

  def show
    update_action_from_order

    respond_to do |format|
      format.html
      format.svg  { render qrcode: basket_with_uid_url(@basket.uid), level: :l, unit: 6, offset: 10 }
    end
  end

  def set_admin
    cookie_set(:admin, @basket.uid)
    redirect_to basket_path(@basket.uid), notice: 'You have been set as admin.'
  end

  def share
    cookie_set(:action, :share_link)
  end

  private
  def update_action_from_order
    return unless @order
    cookie_set(:action, @order.paid? ?  :wait : :pay_order)
  end
end
