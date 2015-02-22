# encoding: utf-8

class PassthroughController < ApplicationController
  include CookieHelper

  skip_before_action :verify_authenticity_token
  skip_before_action :reset_flow_cookies

  before_action :resolve_mode

  after_filter :add_missing_content_type

  def pass
    if env['PATH_INFO'].include?('reporterror')
      logger.warn "Blocked reporterror: #{env['PATH_INFO']}"
      env['rack.input'].rewind
      logger.warn Rack::Utils.parse_nested_query(env['rack.input'].read)
      render text: 'withheld error from pizza.de', status: 500
    else
      rewrite
    end
  end

  def pass_root
    env['PATH_INFO'] = "/"
    rewrite
  end

  private

  # Reads the mode cookies and ensures it’s valid and all dependencies are, too.
  # If something is wrong, it redirects to the start page with an error message.
  def resolve_mode
    @mode = cookie_get(:mode).to_s
    unless VALID_MODES.include?(@mode)
      flash[:error] = t 'mode.invalid_or_missing'
      return redirect_to root_url
    end

    require_basket unless @mode.end_with?('_basket_new')
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
    return if replace

    fix_host!(env['rack.input'].string) if request.post?

    code, headers, body = *forwarder.call(env)
    body = body.first
    if body.encoding.to_s == 'UTF-8'
      inject!(body)
      fix_urls!(body)
    end

    type = headers['content-type'].first rescue 'text/plain'

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
    @forwarder ||= Forwarder.new("pizza.de")
  end
end
