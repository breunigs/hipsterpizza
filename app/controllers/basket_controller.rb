# encoding: utf-8

class BasketController < ApplicationController
  before_filter :find_basket, except: [:new, :create]

  def new
    cookies['_hipsterpizza_action'] = :choose_shop
    cookies['_hipsterpizza_basket'] = nil
    cookies['_hipsterpizza_admin'] = nil
    redirect_to pizzade_root_path
  end

  def create
    b = Basket.create(params.permit(:shop_name, :shop_url))
    if b.errors.any?
      msgs = "\n• " + b.errors.full_messages.join("\n• ")
      render text: "Could not create basket. Messages: #{msgs}"
      # TODO: nicer rendering
    else
      cookies['_hipsterpizza_action'] = :share_link
      cookies['_hipsterpizza_basket'] = b.uid
      cookies['_hipsterpizza_admin'] = b.uid

      redirect_to share_basket_path(b.uid)
    end
  end

  def show
    respond_to do |format|
      format.html
      format.svg  { render qrcode: basket_url(@basket.uid), level: :l, unit: 6, offset: 10 }
    end
  end

  def set_admin
    cookies['_hipsterpizza_basket'] = @basket.uid
    redirect_to basket_path(@basket.uid), notice: 'You have been set as admin.'
  end

  private

  def find_basket
    uid = params[:uid]
    uid ||= cookies['_hipsterpizza_basket']
    @basket = Basket.where(uid: uid).first

    # ensure cookies and URL match up
    cookies['_hipsterpizza_basket'] = @basket ? @basket.uid : nil

    # handle failure
    unless @basket
      flash[:error] = uid ? 'Missing Basket-ID. Ask someone to share the link with you or create initiate a new group order.' : 'Invalid Basket-ID. Are you sure there are no typos and that it is recent?'
      redirect_to root_path(uid: uid)
    end
  end
end
