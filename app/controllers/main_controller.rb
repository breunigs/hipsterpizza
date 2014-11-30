class MainController < ApplicationController
  include CookieHelper

  before_action :find_basket

  def chooser
    b = Basket.find_basket_for_single_mode
    return redirect_to b if b
  end

  def find
    return redirect_to @basket if @basket

    flash[:error] = t 'main.controller.invalid_basket_id'
    render 'chooser'
  end

  def set_nick
    cookie_set(:nick, params[:nick])
    target = request.referer || @basket || root_path
    redirect_to target
  end

  def toggle_admin
    cookie_set(:is_admin, !view_context.admin?)
    render json: { reload: true }
  end
end
