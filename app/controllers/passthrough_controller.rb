# encoding: utf-8

class PassthroughController < ApplicationController
  include CookieHelper

  skip_before_action :verify_authenticity_token
  skip_before_action :reset_flow_cookies

  before_action :filter_error_reporter
  before_action :resolve_state

  after_filter :add_missing_content_type

  rescue_from Mode::InvalidMode do
    flash[:error] = t 'mode.invalid_or_missing'
    return redirect_to root_url
  end

  rescue_from Provider::InvalidProvider do
    flash[:error] = t 'provider.invalid_or_missing'
    return redirect_to root_url
  end

  def pass
    replace || rewrite
  end

  def provider_root
    env['PATH_INFO'] = "/"
    rewrite
  end

  private

  def filter_error_reporter
    return unless env['PATH_INFO'].include?('reporterror')

    logger.warn "Blocked reporterror: #{env['PATH_INFO']}"
    env['rack.input'].rewind
    logger.warn Rack::Utils.parse_nested_query(env['rack.input'].read)
    render text: 'withheld error from pizza.de', status: 500
  end

  def resolve_state
    @mode = Mode.current(cookies)
    @provider = Provider.current(cookies)
    require_basket if @mode.requires_basket?
    response.headers['Content-Security-Policy'] = @provider.csp
  end

  def add_missing_content_type
    return if headers['Content-Type']

    content = mime_type_by_ending
    content << '; charset=utf-8' if content.include?('text')
    headers['Content-Type'] ||= content
    logger.debug "Detected content type: #{content}. Final header: #{headers['Content-Type']}"
  end

  def mime_type_by_ending
    ending = request.path.split('.').last
    return 'text/html' if ending.size > 4

    ending = 'html' if ending == 'htm'
    Mime::Type.lookup_by_extension(ending).to_s.dup
  end

  def rewrite
    fix_host!(env['rack.input'].string) if request.post?

    code, headers, body = *forwarder.call(env)
    body = body.first
    if body.encoding.to_s == 'UTF-8'
      inject!(body)
      fix_urls!(body)
    end

    type = headers['content-type'].first rescue 'text/plain'
    fix_headers!(headers)

    response.headers.merge!(headers)
    send_data body, type: type, disposition: 'inline', status: code
  end

  def replace
    map = {
      '/0_image/pizza-de_logoshop_v8.gif' => 'blank.png'
    }
    return false unless map.keys.include?(env['PATH_INFO'])

    target = map[env['PATH_INFO']]
    # TODO: the next line doesn’t work until 4.1, see rails bug #10051
    #path = ActionController::Base.helpers.asset_path(target)
    path = Rails.application.config.assets.prefix + '/' + target
    no_revalidate_for 24.hours
    redirect_to path, status: 301

    true
  end

  def inject!(body)
    # heuristic: assume if the last part contains a dot, it’s not a
    # HTML resource. If it contains more than one slash, it’s a sub page
    # in which we don’t want to inject.
    return if env['PATH_INFO'].count("/") > 1
    return if env['PATH_INFO'].last(5).include?(".")

    body.sub!("<head>", "<head>\n#{get_view(:head_top)}")
    body.sub!(/<body([^>]*)>/, "<body\\1>\n#{get_view(:body_top)}")

    body.sub!("</head>", "#{get_view(:head_bottom)}\n</head>")
    body.sub!("</body>", "#{get_view(:body_bottom)}\n</body>")
  end

  def fix_headers!(headers)
    headers.fetch('set-cookie', []).each do |h|
      h.sub!(/domain=[^;]+/, "domain=#{request.host}")
    end

    headers.fetch('location', []).each.with_index do |h, i|
      next unless h == '/'
      s = cookie_get(:service)
      headers['location'][i] = s ? root_service_path(s) : root_path
    end
  end

  def fix_urls!(body)
    host = forwarder.host

    body.gsub!("http://#{host}/", '/')
    body.gsub!("https://#{host}/", '/')
    body.gsub!('window.location.hostname', 'window.location.host')

    # let JS believe the page was simply reloaded. Also replace our host with
    # the expected one.
    js_current_url_with_fixed_host = "(window.location.protocol + '//' + '#{host}' + window.location.pathname + window.location.search)"
    body.gsub!("document.referrer", js_current_url_with_fixed_host)

  end

  def get_view(where)
    render_to_string partial: "passthrough/inject_#{where}", locals: { environment: env }
  end

  def fix_host!(str)
    our = '%3A%2F%2F' # ://
    our << request.host
    our << "%3A#{request.port}" if request.port != 80

    str.gsub!(our, '%3A%2F%2Fpizza.de')
  end

  def no_revalidate_for(max_age)
    headers['Cache-Control'] = "public, max-age=#{max_age}"
  end

  def forwarder
    @forwarder ||= Forwarder.new(@provider.domain)
  end
end
