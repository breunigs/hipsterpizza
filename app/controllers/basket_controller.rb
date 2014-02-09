# encoding: utf-8

class BasketController < ApplicationController
  include CookieHelper
  include ActionController::Live

  before_filter :find_basket, except: [:new, :create]
  before_filter :ensure_admin, except: [:new, :create, :find, :show, :share, :set_admin, :delivery_arrived, :pdf]
  before_filter :find_order, only: [:show]
  before_filter :reset_replay

  def new
    cookie_set(:action, :choose_shop)
    cookie_delete(:basket)
    cookie_delete(:admin)

    if PINNING['single_basket_mode'] && @basket = Basket.find_editable
      return redirect_to_basket
    end

    add = '?knddomain=1&noflash=1'

    if PINNING['shop_name'] && PINNING['shop_url'] && PINNING['shop_fax']
      params[:shop_name] = PINNING['shop_name']
      params[:shop_url] = PINNING['shop_url']
      params[:fax_number] = PINNING['shop_fax']
      create
    elsif PINNING['shop_url']
      redirect_to PINNING['shop_url'] + add
    else
      redirect_to pizzade_root_path + add
    end
  end

  def create
    @basket = b = Basket.create(params.permit(:shop_name, :shop_url, :fax_number))
    if b.errors.any?
      msgs = "\n• " + b.errors.full_messages.join("\n• ")
      render text: "Could not create basket. Messages: #{msgs}"
      # TODO: nicer rendering
    else
      cookie_set(:action, :share_link)
      cookie_set(:basket, b.uid)
      cookie_set(:admin, b.uid)

      if PINNING['single_basket_mode']
        redirect_to_basket
      else
        redirect_to share_basket_path(b.uid)
      end
    end
  end

  def find
    redirect_to_basket
  end

  def show
    update_action_from_order

    respond_to do |format|
      format.html
      format.svg  { render qrcode: basket_with_uid_url(@basket.uid), level: :l, unit: 6, offset: 10 }
    end
  end

  def submit
    @basket.update_column(:submitted, Time.now)
    @cfg = load_fax_config
    provider = @cfg['order_by_fax'] ? @cfg['fax_provider'] : nil

    case provider
    when 'manual' then
      redirect_to pdf_basket_path(@basket.uuid)
    when 'pdf24' then
      @cfg = load_fax_config
      stream('submit_fax_pdf24')
    else
      cookie_set(:replay, "basket #{get_replay_mode} #{@basket.uid}")
      cookie_set(:action, :submit_group_order)
      redirect_to_shop
    end
  end

  def unsubmit
    @basket.update_column(:submitted, nil)
    flash[:info] = 'Basket has been reopened and further orders may be made.'
    redirect_to_basket
  end

  def set_submit_time
    cookie_set(:action, :mark_delivery_arrived)
    @basket.update_column(:submitted, Time.now)
    @basket.update_column(:sha_address, params[:sha_address])
    redirect_to_basket
  end

  def delivery_arrived
    @basket.update_column(:arrival, Time.now)
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
end
