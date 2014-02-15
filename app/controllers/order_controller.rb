# encoding: utf-8

class OrderController < ApplicationController
  include CookieHelper

  before_filter :find_basket
  before_filter :find_order, except: [:new, :create]
  before_filter :ensure_basket_editable, only: [:create, :new, :destroy, :copy, :edit, :update]
  before_filter :reset_replay

  def new
    cookie_set(:action, :new_order)
    redirect_to_shop
  end

  def edit
    cookie_set(:action, :edit_order)
    cookie_set(:replay, "order nocheck #{@order.uuid}")
    redirect_to_shop
  end

  def save
    so = SavedOrder.new(params.permit(:name))
    so.nick = cookie_get(:nick).strip
    so.nick = 'not specified' if so.nick.blank?
    so.shop_url = @order.basket.shop_url
    so.json = @order.json
    if so.save
      render json: { text: 'saved ✓', disable: true }
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

    redirect_to_basket
  end

  def create
    @order = o = Order.new(params.permit(:nick, :json))
    o.basket_id = @basket.id
    o.save!
    if o.errors.any?
      flash_error_msgs(o)
    else
      cookie_set(:order, o.uuid)
      cookie_set(:action, :pay_order)
      flash[:info] = "Your order has been added. Please put #{view_context.sum} on the money pile."
    end
    redirect_to_basket
  end

  def toggle_paid
    @order.toggle(:paid).save
    if request.xhr?
      return render json: { }
    else
      return redirect_to_basket
    end
  end

  def destroy
    return redirect_to_basket unless @order

    my_order = cookie_get(:order) == @order.uuid
    if !my_order && !view_context.admin?
      flash[:warn] = 'Only admins can delete other people’s orders.'
      return redirect_to_basket
    end

    sum = @order.paid? ? @order.sum : 0
    @order.destroy!
    cookie_delete(:order) if my_order

    flash[:info] = "#{my_order ? 'Your' : @order.nick.possessive} order has been removed."
    flash[:info] << " Don’t forget to take  #{view_context.sum} from the pile." if sum > 0

    redirect_to_basket
  end


  def copy
    cookie_set(:replay, "order #{get_replay_mode} #{@order.uuid}")
    cookie_set(:action, :new_order)
    redirect_to_shop
  end

  private
  def ensure_basket_editable
    if @basket.cancelled?
      flash[:error] = 'This group order has been cancelled. Please ask someone for the new link.'
      redirect_to basket_path
    elsif !@basket.submitted.nil?
      flash[:error] = 'This group order has already been submitted. Please talk to whoever ordered the food to add your order manually via phone.'
      # TODO: repeat order here for convenience
      redirect_to_basket
    end
  end

  def flash_error_msgs(order)
    return if order.errors.none?
    msgs = errors_to_fake_list(order)
    flash[:error] = "Could not create order. Messages: #{msgs}"
  end

  def handle_price_difference(pay, pay_tip)
    vc = view_context
    flash[:info] = 'Your order has been updated. ' + if pay == 0
      cookie_set(:action, :wait)
      'The price didn’t change, so no worries here.'
    elsif pay < 0
      cookie_set(:action, :wait)
      "Please take #{vc.euro(pay.abs)} (or #{vc.euro(pay_tip.abs)} if you tipped) from the money pile."
    else
      @order.update_column(:paid, false)
      cookie_set(:action, :pay_order)
      "You need to pay an additional  #{view_context.sum(pay, pay_tip)}."
    end
  end
end
