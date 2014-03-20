# encoding: utf-8

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


  def find_basket
    uid = params[:basket_uid]
    uid ||= cookie_get(:basket)
    uid.downcase! if uid
    @basket = Basket.where(uid: uid).first rescue nil

    @basket ||= Basket.find_basket_for_single_mode

    # ensure cookies and URL match up
    cookie_set(:basket, @basket ? @basket.uid : nil)

    # handle failure
    unless @basket
      flash[:error] = uid ? 'Invalid Basket-ID. Are you sure there are no typos and that it is recent?' : 'Missing Basket-ID. Ask someone to share the link with you or create initiate a new group order.'
      redirect_to root_path(uid: uid)
    end
  end

  def find_order
    @order = Order.where(uuid: params[:order_uuid]).first rescue nil
    @order ||= Order.where(uuid: cookie_get(:order), basket: @basket).first rescue nil
    @saved_order = SavedOrder.where(uuid: params[:saved_order_uuid]).first rescue nil
  end

  def redirect_to_basket
    redirect_to basket_with_uid_path(@basket.uid)
  end

  def redirect_to_shop
    # knddomain=1 hides pizza.de related branding and logins
    redirect_to @basket.shop_url + '?knddomain=1&noflash=1'
  end

  def get_replay_mode
    modes = ['insta', 'nocheck', 'check']
    p = params[:mode]
    return p if modes.include?(p)
    logger.warn "Invalid Replay Mode: #{p}" unless p.blank?
    modes.last
  end

  def reset_replay
    cookie_delete(:replay)
  end

  def stream(template)
    response.headers['X-Accel-Buffering'] = 'no'

    # via http://stackoverflow.com/a/748646/1684530
    # ensure that streamed pages are never cached
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"

    begin
      @stream = response.stream
      @header, @footer = *splitted_app_layout
      render template, layout: false
    rescue IOError
    ensure
      @stream.close
    end
  end

  private
  def splitted_app_layout
    # FIXME: this is an ugly hack because there doesn’t seem to be an
    # easy way to have a normal layout *and* stream the content
    # generated here. Use render_to_body instead of render_to_string
    # becuase the latter overwrites response.stream somehow, breaking
    # the streaming (https://github.com/rails/rails/pull/11623)
    layout = render_to_body(file: '/layouts/application', layout: false)
    layout = layout.partition('</body>')
    [layout[0], layout[1..-1].join]
  end

  def errors_to_fake_list(obj)
    "\n• " + obj.errors.full_messages.join("\n• ")
  end
end
