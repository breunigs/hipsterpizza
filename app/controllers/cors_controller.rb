class CorsController < ActionController::Base
  # include CookieHelper

  # skip_before_action :verify_authenticity_token
  # skip_before_action :reset_flow_cookies

  rescue_from Provider::InvalidProvider do
    flash[:error] = t 'provider.invalid_or_missing'
    return redirect_to root_url
  end

  before_action do
    @provider = Provider.current(cookies)
  end

  def pass
    raise 'method not supported' unless request.get?

    url = URI.parse(params[:url])
    raise 'unpassable host' unless @provider.passable_host?(url.host)

    code, headers, body = *Forwarder.new(url.host).call(env)
    type = headers['content-type'].try(:first) || 'text/plain'

    send_data body.first, type: type, disposition: 'inline', status: code
  end
end
