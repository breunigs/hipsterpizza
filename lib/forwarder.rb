# encoding: utf-8

# via https://gist.github.com/chneukirchen/32376

require 'net/http'
require 'rack'

class Forwarder
  def initialize(host, port=443)
    @host, @port = host, port
  end

  def call(env)
    req = request(env)

    res = http.request(req)
    res_hash = res.to_hash
    fix_encoding!(res, res_hash)

    [res.code, Rack::Utils::HeaderHash.new(res_hash), [res.body]]
  end

  private

  def guess_charset(res_hash)
    res_hash["content-type"].join(" ").match(/charset=([^\s]+)/)[1] rescue nil
  end

  def fix_encoding!(resource, res_hash)
    charset = guess_charset(res_hash)
    return unless charset
    resource.body.encode!('utf-8', charset, invalid: :replace, undef: :replace, :replace => '♥') if charset != "utf-8"
  end

  def http
    return @connection if @connection

    @connection = h = Net::HTTP.new(@host, @port)
    h.use_ssl = true
    # TODO: move to config
    h.ca_path = '/etc/ssl/certs'
    h.verify_mode = OpenSSL::SSL::VERIFY_PEER
    h.verify_depth = 10
    h
  end

  def request(env)
    rackreq = Rack::Request.new(env)

    m = rackreq.request_method
    path = rackreq.fullpath.blank? ? "/" : rackreq.fullpath

    case m
    when "GET", "HEAD", "DELETE", "OPTIONS", "TRACE"
      req = Net::HTTP.const_get(m.capitalize).new(path, headers(env))
    when "PUT", "POST"
      req = Net::HTTP.const_get(m.capitalize).new(path, headers(env))
      req.body_stream = rackreq.body
    else
      raise "method not supported: #{method}"
    end
    req
  end

  def headers(env)
    h = Rack::Utils::HeaderHash.new
    env.each do |key, value|
      h[$1] = value if key =~ /HTTP_(.*)/
    end

    h["HOST"] = "#{@host}:#{@port}"
    h
  end
end
