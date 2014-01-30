# encoding: utf-8

# via https://gist.github.com/chneukirchen/32376

require 'net/http'
require 'rack'
require 'pp'

class Forwarder
  def initialize(host, port=443)
    @host, @port = host, port
  end

  def call(env)
    req = request(env)

    begin
      res = http.request(req)
    rescue Net::HTTPBadResponse => e
      puts "="*30
      pp req.path
      pp e
      pp caller
      puts "="*30
    end


    res_hash = res.to_hash
    fix_encoding!(res, res_hash)

    [res.code, Rack::Utils::HeaderHash.new(res_hash), [res.body]]
  end

  private

  def guess_charset(res_hash)
    res_hash["content-type"].join(" ").match(/charset=([^\s]+)/)[1] rescue nil
  end

  def is_text?(res_hash)
    h = (res_hash["content-type"] || []).join(" ")
    h.include?("text") || h.include?("charset=") || h == "application/x-javascript"
  end

  def fix_encoding!(resource, res_hash)
    return unless is_text?(res_hash)
    Rails.logger.warn "RES_HASH is text"

    charset = guess_charset(res_hash)
    if charset == 'utf-8'
      resource.body.encode!('utf-8', 'utf-8')
      return
    end


    # if it’s a text resource without given encoding, it’s most likely
    # encoded in iso-8859-1. This may change if pizza.de updates their
    # code.
    charset ||= 'iso-8859-1'
    # convert to UTF-8 and update HTML headers as well as embedded meta-
    # tags.
    resource.body.encode!('utf-8', charset, invalid: :replace, undef: :replace, :replace => '♥')
    res_hash['content-type'].each { |x| x.sub!(charset, 'utf-8') }
    resource.body.sub!(/content="text\/html; charset=[^"]+"/, 'content="text/html; charset=utf-8"')
  end

  def http
    h = Net::HTTP.new(@host, @port)

    h.use_ssl = true
    # TODO: move to config
    h.ca_path = '/etc/ssl/certs'
    h.verify_mode = OpenSSL::SSL::VERIFY_PEER
    h.verify_depth = 10
    h.read_timeout = 30
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
      req.body = rackreq.body.to_s
    else
      raise "method not supported: #{method}"
    end
    req
  end

  def headers(env)
    h = Rack::Utils::HeaderHash.new
    env.each do |key, value|
      next if key == 'HTTP_REFERER'
      h[$1] = value if key =~ /HTTP_(.*)/
    end

    # do net send hipsterpizza cookies to pizza.de
    if h["COOKIE"]
      h["COOKIE"].gsub!(/_hipsterpizza_[^;,\s]+;?/, "")
      h["COOKIE"].strip!
    end

    h["HOST"] = "#{@host}:#{@port}"
    h
  end
end
