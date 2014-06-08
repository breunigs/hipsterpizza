# encoding: utf-8

class OrderController < ApplicationController
  include CookieHelper

  before_filter :require_basket
  before_filter :require_order, except: [:new, :create]
  before_filter :ensure_basket_editable, only: [:create, :new, :destroy, :copy, :edit, :update]

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
      render json: { text: t('button.save_order.link_saved'), disable: true }
    else
      render json: { text: 'error ☹', error: so.errors }
    end
  end

  def update
    pay     = @order.paid? ? @order.sum : 0
    pay_tip = @order.paid? ? @order.sum_with_tip : 0

    @order.json = params[:json]
    @order.save!

    if @order.errors.any?
      flash_error_msgs(@order)
    else
      pay = @order.sum - pay
      pay_tip = @order.sum_with_tip - pay_tip

      handle_price_difference(pay, pay_tip)
    end

    redirect_to @basket
  end

  def create
    @order = o = Order.new(params.permit(:nick, :json))
    o.basket_id = @basket.id

    unless o.save
      flash_error_msgs(o)
    else
      price = render_to_string 'order/_price', layout: false
      flash[:info] = t('order.controller.create', price: price).html_safe
    end
    redirect_to @basket
  end

  def toggle_paid
    @order.toggle(:paid).save
    if request.xhr?
      return render json: { }
    else
      return redirect_to @basket
    end
  end

  def destroy
    return redirect_to @basket unless @order

    my_order = @nick == @order.nick
    unless my_order || view_context.admin?
      flash[:warn] = I18n.t('order.controller.destroy.admin_required')
      return redirect_to @basket
    end

    price = render_to_string 'order/_price', layout: false if @order.paid?
    @order.destroy!

    i18n_key = my_order ? 'my_order' : 'other_order'
    flash[:info] = I18n.t("order.controller.destroy.#{i18n_key}")
    if @order.paid?
      flash[:info] << ' '
      flash[:info] << I18n.t('order.controller.money.take', price: price)
    end

    redirect_to @basket
  end


  def copy
    if @order.updated_at > 1.hour.ago && get_replay_mode == 'insta'
      params[:json] = @order.json
      params[:nick] = @nick
      return create
    else
      cookie_set(:replay, "order #{get_replay_mode} #{@order.uuid}")
      cookie_set(:mode, :pizzade_order_new)
      redirect_to_shop
    end
  end

  private
  def ensure_basket_editable
    if @basket.cancelled?
      flash[:error] = 'This group order has been cancelled. Please ask someone for the new link.'
      redirect_to basket_path
    elsif !@basket.submitted.nil?
      flash[:error] = 'This group order has already been submitted. Please talk to whoever ordered the food to add your order manually via phone.'
      # TODO: repeat order here for convenience
      redirect_to @basket
    end
  end

  def flash_error_msgs(order)
    return if order.errors.none?
    msgs = errors_to_fake_list(order)
    flash[:error] = "Could not create order. Messages: #{msgs}"
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

    # TODO FIXME continue here by generating fake Order object with pay/pay_tip
    # as sum/sum_with_tip
    fake = OpenStruct.new(sum: pay, sum_with_tip: pay_tip)

    price = render_to_string 'order/_price', layout: false, order: fake

    flash[:info] = I18n.t('order.controller.update') << ' '
    flash[:info] << I18n.t("order.controller.money.#{i18n_key}", price: price)
  end

  def require_order
    @order = Order.friendly.find(params[:id]) rescue nil
    unless @order
      flash[:error] = t('order.controller.invalid_uuid')
      return redirect_to @basket
    end
  end
end
