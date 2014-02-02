# encoding: utf-8

class BasketController < ApplicationController
  include CookieHelper

  before_filter :find_basket, except: [:new, :create]
  before_filter :ensure_admin, except: [:new, :create, :show, :share, :set_admin]
  before_filter :find_order, only: [:show]
  before_filter :reset_replay

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

  def submit
    @basket.update_column(:submitted, Time.current)
    cookie_set(:replay, "basket #{get_replay_mode} #{@basket.uid}")
    cookie_set(:action, :submit_group_order)
    redirect_to_shop
  end

  def unsubmit
    @basket.update_column(:submitted, nil)
    flash[:info] = 'Basket has been reopened and further orders may be made.'
    redirect_to_basket
  end

  def set_admin
    cookie_set(:admin, @basket.uid)
    flash[:info] = 'You have been set as admin.'
    redirect_to_basket
  end

  def share
    cookie_set(:action, :share_link)
  end

  def toggle_cancelled
    @basket.toggle(:cancelled).save
    if @basket.cancelled?
      flash[:info] = "Group order has been cancelled"
    else
      flash[:success] = "Group order has been enabled again"
    end
    redirect_to_basket
  end

  private
  def update_action_from_order
    if @order
      cookie_set(:action, @order.paid? ?  :wait : :pay_order)
      cookie_set(:action, :share_link) if view_context.admin? && @order.paid?
    else
      cookie_set(:action, view_context.admin? ? :share_link : nil)
    end
  end

  def ensure_admin
    unless view_context.admin?
      flash[:error] = 'You are not an admin, no action taken.'
      redirect_to_basket
    end
  end
end
