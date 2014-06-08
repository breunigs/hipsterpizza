# encoding: utf-8

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_locale
  before_action :reset_flow_cookies
  before_action :find_nick

  def reset_flow_cookies
    cookie_delete(:mode)
    cookie_delete(:replay)
  end

  # reads nick from cookie into @nick
  def find_nick
    @nick ||= cookie_get(:nick).to_s
  end

  # Tries to fill the @basket variable with an appropriate Basket model.
  # Order of preference:
  # 1. URL UID
  # 2. editable basket in single basket mode
  # 3. recently submitted basket in single basket mode
  # 4. cookies
  def find_basket
    basket_id = params[:basket_id] || params[:id]
    @basket ||= Basket.friendly.find(basket_id.downcase) rescue nil
    # if there’s an id, but it’s invalid it should ignore the cookie.
    return nil unless @basket || params[:basket_id].blank?

    @basket ||= Basket.find_basket_for_single_mode
    @basket ||= Basket.friendly.find(cookie_get(:basket)) rescue nil
  end

  # Ensures the @basket variable contains a Basket-model. If all fail, the user
  # will be redirect to the main page without an error message. Order of
  # preference is the same as in find_basket.
  def require_basket
    find_basket
    return redirect_to root_path unless @basket
    cookie_set(:basket, @basket.uid)
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
    # because the latter overwrites response.stream somehow, breaking
    # the streaming (https://github.com/rails/rails/pull/11623)
    layout = render_to_body(file: '/layouts/application', layout: false)
    layout = layout.partition('</body>')
    [layout[0], layout[1..-1].join]
  end

  # TODO: deprecate. Should use view instead
  def errors_to_fake_list(obj)
    "\n• " + obj.errors.full_messages.join("\n• ")
  end

  def set_locale
    avail = I18n.available_locales
    I18n.locale = http_accept_language.compatible_language_from(avail)
  end
end
