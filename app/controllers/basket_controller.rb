# encoding: utf-8

class BasketController < ApplicationController
  include CookieHelper

  before_filter :find_basket, except: [:new, :create]
  before_filter :ensure_admin, except: [:new, :create, :find, :show, :share, :set_admin, :delivery_arrived, :pdf]
  before_filter :find_order, only: [:show]
  before_filter :reset_replay

  PIZZADE_URL_MODIFIERS = '?knddomain=1&noflash=1'

  def new
    cookie_set(:action, :choose_shop)
    cookie_delete(:basket)
    cookie_delete(:admin)

    if PINNING['single_basket_mode'] && @basket = Basket.find_editable
      return redirect_to_basket
    end

    fields = %w(name url fax)
    if all_pinned?(fields)
      copy_pinned_to_params(fields)
      create
    elsif PINNING['shop_url']
      redirect_to PINNING['shop_url'] + PIZZADE_URL_MODIFIERS
    else
      redirect_to pizzade_root_path + PIZZADE_URL_MODIFIERS
    end
  end

  def create
    @basket = Basket.create(params.permit(:shop_name, :shop_url, :shop_fax))

    if @basket.errors.any?
      msgs = errors_to_fake_list(b)
      flash[:error] = "Could not create basket. Messages: #{msgs}"
      return redirect_to root_path
    end

    cookie_set(:action, :share_link)
    cookie_set(:basket, @basket.uid)
    cookie_set(:admin, @basket.uid)
    cookie_delete(:order)

    if PINNING['single_basket_mode']
      redirect_to_basket
    else
      redirect_to share_basket_path(@basket.uid)
    end
  end

  def find
    redirect_to_basket
  end

  def show
    if flash.empty?
      keys = [@basket.cache_key, @order.cache_key, view_context.admin?, @basket.clock_running?]
      return unless stale?(etag: keys.join(' '))
    end

    update_action_from_order

    respond_to do |format|
      format.html
      format.svg  { render qrcode: basket_with_uid_url(@basket.uid), level: :l, unit: 6, offset: 10 }
    end
  end

  def unsubmit
    @basket.update_attribute(:submitted, nil)
    flash[:info] = 'Basket has been reopened and further orders may be made.'
    redirect_to_basket
  end

  def set_submit_time
    cookie_set(:action, :mark_delivery_arrived)
    @basket.update!(submitted: Time.now, sha_address: params[:sha_address])
    redirect_to_basket
  end

  def delivery_arrived
    @basket.update_attribute(:arrival, Time.now)
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

  def pdf
    @cfg = load_fax_config
    response.headers['Content-Disposition'] = %|INLINE; FILENAME="#{@basket.fax_filename}"|
    response.headers['Content-Type'] = 'application/pdf'
    render 'fax.pdf'
  end

  private
  def update_action_from_order
    admin_action = @basket.submitted? ? :mark_delivery_arrived : :share_link
    if @order
      cookie_set(:action, @order.paid? ?  :wait : :pay_order)
      cookie_set(:action, admin_action) if view_context.admin? && @order.paid?
    else
      cookie_set(:action, view_context.admin? ? admin_action : nil)
    end
  end

  def ensure_admin
    unless view_context.admin?
      flash[:error] = 'You are not an admin, no action taken.'
      redirect_to_basket
    end
  end

  def all_pinned?(fields)
    fields.all? { |f| PINNING["shop_#{f}"] }
  end

  def copy_pinned_to_params(fields)
    fields.each do |f|
      f = "shop_#{f}"
      params[f.to_sym] = PINNING[f]
    end
  end
end
