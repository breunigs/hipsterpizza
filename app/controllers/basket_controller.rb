# encoding: utf-8

class BasketController < ApplicationController
  def new
    cookies['_hipsterpizza_action'] = :choose_shop
    cookies['_hipsterpizza_basket'] = nil
    cookies['_hipsterpizza_admin'] = nil
    redirect_to pizzade_root_path
  end

  def create
    b = Basket.create(params.permit(:shop_xname, :shop_url))
    if b.errors.any?
      msgs = "\n• " + b.errors.full_messages.join("\n• ")
      render text: "Could not create basket. Messages: #{msgs}"
      # TODO: nicer rendering
    else
      cookies['_hipsterpizza_action'] = :place_order
      cookies['_hipsterpizza_basket'] = b.uid
      cookies['_hipsterpizza_admin'] = b.uid


    end
  end
end
