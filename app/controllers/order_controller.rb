# encoding: utf-8

class OrderController < ApplicationController
  include CookieHelper

  before_filter :find_basket

  def new
    cookie_set(:action, :new_order)
    redirect_to root_url + @basket.shop_url[1..-1] + '?knddomain=1'
  end

  before_filter :ensure_basket_editable, only: :create
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
      redirect_to basket_path
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
      redirect_to basket_path
    end
  end
end
