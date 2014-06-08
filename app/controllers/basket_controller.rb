# encoding: utf-8

class BasketController < ApplicationController
  include CookieHelper

  before_filter :ensure_admin, except: [:new, :create, :find, :show, :share, :set_admin, :delivery_arrived, :pdf]

  before_action :require_basket, except: [:new, :create, :find]

  PIZZADE_URL_MODIFIERS = '?knddomain=1&noflash=1'

  def new
    # if there’s an editable basket and we are in single basket mode,
    # redirect directly to basket instead of creating new one
    if PINNING['single_basket_mode']
      @basket = Basket.find_editable
      return redirect_to_basket unless @basket.nil?
    end

    fields = %w(name url fax)
    if all_pinned?(fields)
      copy_pinned_to_params(fields)
      return create
    end

    cookie_set(:mode, :pizzade_basket_new)

    url = PINNING['shop_url'] || pizzade_root_path
    redirect_to url + PIZZADE_URL_MODIFIERS
  end

  def create
    @basket = Basket.create(params.permit(:shop_name, :shop_url, :shop_fax))

    if @basket.errors.any?
      msgs = errors_to_fake_list(@basket)
      flash[:error] = t('basket.controller.create.errors', messages: msgs)
      return redirect_to root_path
    end

    cookie_set(:is_admin, true)

    if PINNING['single_basket_mode']
      redirect_to_basket
    else
      redirect_to share_basket_path(@basket.uid)
    end
  end

  def show
    # if flash.empty?
    #   keys = [@basket.cache_key, @order.cache_key, view_context.admin?, @basket.clock_running?]
    #   return unless stale?(etag: keys.join(' '))
    # end
    @order = Order.where(basket_id: @basket.id, nick: @nick).first

    respond_to do |format|
      format.html
      format.svg  { render qrcode: basket_path(@basket), level: :l, unit: 6, offset: 10 }
    end
  end

  def unsubmit
    @basket.update_attribute(:submitted, nil)
    flash[:info] = t 'basket.controller.reopened'
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
    flash[:info] = t 'basket.controller.set_admin'
    redirect_to_basket
  end

  def share
  end

  def toggle_cancelled
    @basket.toggle(:cancelled).save
    if @basket.cancelled?
      flash[:warning] = t 'basket.controller.group_order.cancelled'
    else
      flash[:success] = t 'basket.controller.group_order.reenabled'
    end
    redirect_to @basket
  end

  def pdf
    @cfg = load_fax_config
    response.headers['Content-Disposition'] = %|INLINE; FILENAME="#{@basket.fax_filename}"|
    response.headers['Content-Type'] = 'application/pdf'
    render 'fax.pdf'
  end

  private

  def ensure_admin
    unless view_context.admin?
      flash[:error] = t 'basket.controller.not_admin'
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
