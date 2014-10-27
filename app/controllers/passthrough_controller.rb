# encoding: utf-8

class PassthroughController < ApplicationController
  include CookieHelper

  @@forwarder = Forwarder.new("pizza.de")

  skip_before_action :verify_authenticity_token
  skip_before_action :reset_flow_cookies

  before_action :resolve_mode

  after_filter :add_missing_content_type

  # cache some of the probably non-static elements. In the worst case
  # an element is 3 hours out of date, i.e. when the client requests a
  # page just before it expires in Rails and won’t re-validate it for
  # another 90 minutes.
  caches_action :pass, expires_in: 90.minutes, if: Proc.new {
    if short_time_cachable?
      no_revalidate_for(90.minutes)
      true
    else
      false
    end
  }

  def pass
    if env['PATH_INFO'].include?('reporterror')
      render text: 'withheld error from pizza.de'
    else
      rewrite
    end
  end

  caches_action :pass_cached, expires_in: 24.hours
  def pass_cached
    no_revalidate_for(24.hours)
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
    if ending.size > 4
      logger.debug "Could not detect content type, skipping #{request.path}"
      return 'text/html'
    end

    ending = 'html' if ending == 'htm'
    Mime::Type.lookup_by_extension(ending).to_s.dup
  end

  def rewrite
    env['PATH_INFO'] = "/" if env['PATH_INFO'] == "/pizzade_root"

    return if replace

    fix_host!(env['rack.input'].string) if request.post?

    ret = @@forwarder.call(env)
    inject!(ret)
    fix_urls!(ret)

    type = ret[1]["content-type"].first rescue 'text/plain'

    # send_data does not include the headers from the response object,
    # so include them manually. Required for e.g. CSP.
    headers.merge!(response.headers)
    send_data ret[2].first, type: type, disposition: 'inline', status: ret[0]
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

  def inject!(ret)
    # heuristic: assume if the last part contains a dot, it’s not a
    # HTML resource. If it contains more than one slash, it’s a sub page
    # in which we don’t want to inject.
    return if env['PATH_INFO'].count("/") > 1
    return if env['PATH_INFO'].last(5).include?(".")


    b = ret[2].first

    b.sub!("<head>", "<head>\n#{get_view(:head_top)}")
    b.sub!(/<body([^>]*)>/, "<body\\1>\n#{get_view(:body_top)}")

    b.sub!("</head>", "#{get_view(:head_bottom)}\n</head>")
    b.sub!("</body>", "#{get_view(:body_bottom)}\n</body>")
  end

  def fix_urls!(ret)
    host = @@forwarder.host

    ret[2].first.gsub!("http://#{host}", "")
    ret[2].first.gsub!("https://#{host}", "")
    ret[2].first.gsub!("window.location.hostname", "window.location.host")

    # let JS believe the page was simply reloaded. Also replace our host with
    # the expected one.
    js_current_url_with_fixed_host = "(window.location.protocol + '//' + '#{host}' + window.location.pathname + window.location.search)"
    ret[2].first.gsub!("document.referrer", js_current_url_with_fixed_host)

  end

  def get_view(where)
    render_to_string partial: "passthrough/inject_#{where}", locals: { environment: env }
  end

  def fix_host!(str)
    our = '%3A%2F%2F' # ://
    our << request.host
    our << "%3A#{request.port}" if request.host != 80

    str.gsub!(our, '%3A%2F%2Fpizza.de')
  end

  def short_time_cachable?
    return true if request.url.match(%r{^/0_static/})
    return true if request.url.match(/framek(?:[0-9]{3}\.)+htm$/)
    false
  end

  def no_revalidate_for(max_age)
    headers['Cache-Control'] = "public, max-age=#{max_age}"
  end
end
