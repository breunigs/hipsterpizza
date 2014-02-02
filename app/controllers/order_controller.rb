# encoding: utf-8

class OrderController < ApplicationController
  include CookieHelper

  before_filter :find_basket
  before_filter :find_order, except: [:new, :create]

  def new
    cookie_set(:action, :new_order)
    redirect_to_shop
  end

  before_filter :ensure_basket_editable, only: [:create, :destroy, :copy]
  def create
    o = Order.new(params.permit(:nick, :json))
    o.basket_id = @basket.id
    o.save!
    if o.errors.any?
      msgs = "\n• " + o.errors.full_messages.join("\n• ")
      render text: "Could not create order. Messages: #{msgs}"
      # TODO: nicer rendering
    else
      cookie_set(:order, o.uuid)
      cookie_set(:action, :pay_order)
      redirect_to_basket
    end
  end

  def toggle_paid
    @order.toggle(:paid).save
    return redirect_to_basket
  end

  def destroy
    redirect_to_basket unless @order

    amount = @order.paid? ? @order.amount : 0
    @order.destroy!
    cookie_delete(:order)

    flash[:info] = 'Your order has been removed.'
    flash[:info] << " Don’t forget to take your #{view_context.euro(amount)} (or #{view_context.euro(@order.amount_with_tip)} with tip) from the pile." if amount > 0

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
      flash[:error] = 'This group order has been canceled. Please ask someone for the new link.'
      redirect_to basket_path
    elsif !@basket.submitted.nil?
      flash[:error] = 'This group order has already been submitted. Please talk to whoever ordered the food to add your order manually via phone.'
      # TODO: repeat order here for convenience
      redirect_to_basket
    end
  end
end
