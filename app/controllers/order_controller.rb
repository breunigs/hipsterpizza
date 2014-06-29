# encoding: utf-8

class OrderController < ApplicationController
  include CookieHelper

  before_filter :require_basket
  before_filter :require_order, except: [:new, :create]
  before_filter :ensure_basket_editable,
                only: [:create, :new, :destroy, :copy, :edit, :update]

  def new
    cookie_set(:mode, :pizzade_order_new)
    redirect_to_shop
  end

  def edit
    cookie_set(:mode, :pizzade_order_edit)
    cookie_set(:replay, "order nocheck #{@order.uuid}")
    redirect_to_shop
  end

  def save
    so = SavedOrder.new(params.permit(:name))
    so.nick = @nick.strip
    so.nick = 'not specified' if so.nick.blank?
    so.shop_url = @order.basket.shop_url
    so.json = @order.json
    if so.save
      render json: { text: t('button.save_order.link.saved'), disable: true }
    else
      render json: { error: so.errors }
    end
  end

  def update
    old_pay     = @order.paid? ? @order.sum : 0
    old_pay_tip = @order.paid? ? @order.sum_with_tip : 0

    @order.json = params[:json]

    if @order.save
      pay = @order.sum - old_pay
      pay_tip = @order.sum_with_tip - old_pay_tip

      handle_price_difference(pay, pay_tip)
    else
      flash_error_msgs(@order)
    end

    redirect_to @basket
  end

  def create
    @order = Order.new(params.permit(:nick, :json))
    @order.basket_id = @basket.id

    if @order.save
      price = render_to_string 'order/_price', layout: false
      flash[:info] = t('order.controller.create', price: price).html_safe
    else
      flash_error_msgs(@order)
    end
    redirect_to @basket
  end

  def toggle_paid
    @order.toggle(:paid).save
    if request.xhr?
      return render json: {}
    else
      key = "order.controller.toggle_paid.#{@order.paid? ? 'is' : 'not'}_paid"
      flash[:info] = t(key, nick: @order.nick.possessive)
      return redirect_to @basket
    end
  end

  def destroy
    unless view_context.my_order? || view_context.admin?
      flash[:warn] = I18n.t('order.controller.destroy.admin_required')
      return redirect_to @basket
    end

    i18n_key = view_context.my_order? ? 'my_order' : 'other_order'
    flash[:info] = I18n.t("order.controller.destroy.#{i18n_key}")

    if @order.paid?
      price = render_to_string 'order/_price', layout: false
      flash[:info] << ' ' << I18n.t('order.controller.money.take', price: price)
    end

    @order.destroy!
    redirect_to @basket
  end

  def copy
    if @order.updated_at > 1.hour.ago && replay_mode == 'insta'
      params[:json] = @order.json
      params[:nick] = @nick
      return create
    else
      cookie_set(:replay, "order #{replay_mode} #{@order.uuid}")
      cookie_set(:mode, :pizzade_order_new)
      redirect_to_shop
    end
  end

  private

  def ensure_basket_editable
    if @basket.cancelled?
      flash[:error] = I18n.t('order.controller.cancelled')
      redirect_to @basket
    elsif @basket.submitted?
      prefix = 'order.controller.already_submitted'
      flash[:error] = I18n.t("#{prefix}.main")
      flash[:error] << I18n.t("#{prefix}.has_order", order: @order) if @order
      redirect_to @basket
    end
  end

  def flash_error_msgs(order)
    return if order.errors.none?
    msgs = errors_to_fake_list(order)
    flash[:error] = I18n.t('order.controller.failure', msgs: msgs)
  end

  def handle_price_difference(pay, pay_tip)
    i18n_key = if pay == 0
      'no_change'
    elsif pay < 0
      'take'
    else
      @order.update_attribute(:paid, false)
      'give'
    end

    fake = OpenStruct.new(sum: pay, sum_with_tip: pay_tip)
    price = render_to_string 'order/_price', layout: false, order: fake

    flash[:info] = I18n.t('order.controller.update') << ' '
    flash[:info] << I18n.t("order.controller.money.#{i18n_key}", price: price)
  end

  def require_order
    @order = Order.friendly.find(params[:order_id]) rescue nil
    return if @order
    flash[:error] = t('order.controller.invalid_uuid')
    redirect_to @basket
  end
end
