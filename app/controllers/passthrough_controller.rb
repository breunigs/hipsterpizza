# encoding: utf-8

class PassthroughController < ActionController::Base
  @@forwarder = Forwarder.new("pizza.de")

  after_filter :add_missing_content_type

  # cache some of the probably non-static elements
  caches_action :pass, expires_in: 60.minutes, if: Proc.new {
    path = request.url
    return true if path.match(%r{^/0_static/})
    return true if path.match(/framek[0-9]{3}\.htm$/)
    false
  }

  def pass
    logger.warn "pass: #{headers['Content-Type']}"

    if env['PATH_INFO'].include?("reporterror")
      render text: "withheld error from pizza.de"
    else
      rewrite
    end
  end

  caches_action :pass_cached, expires_in: 24.hours
  def pass_cached
    return rewrite
  end

  private
  def add_missing_content_type
    return if headers['Content-Type']

    content = mime_type_by_ending
    content << "; charset=utf-8" if content.include?("text")
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

    ret = @@forwarder.call(env)
    inject!(ret)
    fix_urls!(ret)

    type = ret[1]["content-type"].first rescue 'text/plain'

    send_data ret[2].first, type: type, disposition: 'inline', status: ret[0]
  end

  def replace
    map = {
      '/0_image/pizza-de_logoshop_v8.gif' => 'blank.png'
    }
    return false unless map.keys.include?(env['PATH_INFO'])

    target = map[env['PATH_INFO']]
    path = ActionController::Base.helpers.asset_path(target)
    redirect_to path, status: 301

    true
  end


  def inject!(ret)
    # heuristic: assume if the last part contains a dot, it’s not a
    # HTML resource. If it contains more than one slash, it’s a sub page
    # in which we don’t want to inject.
    logger.warn env['PATH_INFO']
    return if env['PATH_INFO'].count("/") > 1
    return if env['PATH_INFO'].last(5).include?(".")


    b = ret[2].first

    b.sub!("<head>", "<head>\n#{get_view(:head_top)}")
    b.sub!("<body>", "<body>\n#{get_view(:body_top)}")

    b.sub!("</head>", "#{get_view(:head_bottom)}\n</head>")
    b.sub!("</body>", "#{get_view(:body_bottom)}\n</body>")
  end

  def fix_urls!(ret)
    ret[2].first.gsub!("http://pizza.de", "")
    ret[2].first.gsub!("https://pizza.de", "")
    ret[2].first.gsub!("window.location.hostname", "window.location.host")
  end

  def get_view(where)
    render_to_string partial: "passthrough/inject_#{where}", locals: { environment: env }
  end
end
