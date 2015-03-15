class BasketController < ApplicationController
  include CookieHelper

  before_action :require_basket, except: [:new, :create, :find]
  before_filter :ensure_admin, except: [:new, :create, :find, :show, :share,
                                        :delivery_arrived, :pdf]

  rescue_from Provider::InvalidName do
    flash[:error] = "[i18n] Provider invalid or missing, cannot continue."
    reset_flow_cookies
    redirect_to root_path
  end

  def new

    # if there’s an editable basket and we are in single basket mode,
    # redirect directly to basket instead of creating new one
    if Pinning.single_basket_mode?
      @basket = Basket.find_editable
      return redirect_to @basket unless @basket.nil?
    end

    if Pinning.all_pinned?
      Pinning.merge_pinned!(params)
      return create
    end

    provider = Provider.new(params[:provider] || Pinning.provider)
    cookie_set(:mode, "#{provider.name}_basket_new")

    url = Pinning.shop_url(provider) || provider.new_basket_url
    redirect_to url
  end

  def create
    basket = Basket.create(params.permit(:shop_name, :shop_url, :shop_fax, :shop_url_params))

    if basket.errors.any?
      msgs = errors_to_fake_list(basket)
      flash[:error] = t('basket.controller.create.errors', messages: msgs)
      return redirect_to root_path
    end

    cookie_set(:is_admin, true)

    if PINNING['single_basket_mode']
      redirect_to basket
    else
      redirect_to share_basket_path(basket.uid)
    end
  end

  def show
    @order = Order.where(basket_id: @basket.id, nick: @nick).first

    respond_to do |format|
      format.html

      format.js do
        find_changes
        head :no_content unless @basket_changed || @order_changed
      end

      format.svg  do
        render qrcode: basket_path(@basket), level: :l, unit: 6, offset: 10
      end
    end
  end

  def unsubmit
    @basket.update_attribute(:submitted, nil)
    flash[:info] = t 'basket.controller.reopened'
    redirect_to @basket
  end

  def set_submit_time
    @basket.update!(submitted: Time.now, sha_address: params[:sha_address])
    redirect_to @basket
  end

  def delivery_arrived
    begin
      @basket.update_attribute(:arrival, Time.parse(params[:arrival]))
      render json: { reload: true, disable: true }
    rescue ArgumentError, TypeError
      @basket.update_attribute(:arrival, Time.now)
      flash[:error] = t 'basket.controller.invalid_time'
      render json: { error: flash[:error] }
    end
  end

  def share
  end

  def toggle_cancelled
    if not @basket.toggle(:cancelled).save(validate: false)
      flash[:error] = t 'toggle_failed'
    elsif @basket.cancelled?
      flash[:warn] = t 'basket.controller.group_order.cancelled'
    else
      flash[:success] = t 'basket.controller.group_order.reenabled'
    end
    redirect_to @basket
  end

  def pdf
    @fax_config = load_fax_config
    fn = @basket.fax_filename
    response.headers['Content-Disposition'] = %(INLINE; FILENAME="#{fn}")
    response.headers['Content-Type'] = 'application/pdf'
    render 'fax.pdf'
  end

  private

  def ensure_admin
    return if view_context.admin?
    flash[:error] = t 'basket.controller.not_admin'
    redirect_to @basket
  end

  # detects if @basket or @order have been changed compared to the timestamps
  # in the params (ts_basket and ts_order). It considers a deleted order as
  # newer if it was present before.
  def find_changes
    ts_basket = (params[:ts_basket] || 0).to_i
    @basket_changed = ts_basket < @basket.updated_at.to_i

    ts_option = (params[:ts_order] || 0).to_i
    order_deleted = @order.nil? && ts_option != 0
    order_updated = @order && ts_option < @order.updated_at.to_i
    @order_changed = order_deleted || order_updated
  end
end
