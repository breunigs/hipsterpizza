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
    store.fetch(env) { remote_load(env) }
  end

  attr_reader :host

  private

  def debug(text)
    Rails.logger.debug(text)
  end

  def remote_load(env)
    req = request(env)

    debug "remote loading: #{req.method} #{req.path}"

    begin
      res = http.request(req)
    rescue SocketError => e
      err = "Received socket error when trying to connect to remote host. Do you have internet?\nerror: #{e.inspect}"
      debug err
      return [504, {}, [err]]
    rescue Net::HTTPBadResponse => e
      err = "Received weird response:\npath: #{req.path}\nerror: #{e.inspect}\ncaller: #{caller.inspect}"
      debug err
      return [502, {}, [err]]
    end

    res_hash = res.to_hash
    fix_encoding!(res, res_hash)

    [res.code, Rack::Utils::HeaderHash.new(res_hash), [res.body]]
  end

  def guess_charset(res_hash)
    res_hash["content-type"].join(" ").match(/charset=([^\s]+)/)[1].upcase rescue nil
  end

  def is_text?(res_hash)
    h = (res_hash["content-type"] || []).join(" ")
    h.include?("text") || h.include?("charset=") || h == "application/x-javascript"
  end

  def fix_encoding!(resource, res_hash)
    return unless is_text?(res_hash)

    # if it’s a text resource without given encoding, it’s most likely
    # encoded in iso-8859-1. This may change if pizza.de updates their
    # code.
    charset = guess_charset(res_hash) || 'ISO-8859-1'

    body = resource.body.encode('UTF-8', charset, invalid: :replace, undef: :replace)
    return unless body.valid_encoding?

    resource.body = body
    convert_headers_to_utf8(resource, res_hash, charset)
  end

  def convert_headers_to_utf8(resource, res_hash, from_charset)
    return from_charset == 'UTF-8'

    res_hash['content-type'].each { |x| x.sub!(from_charset, 'UTF-8') }
    # HTML meta tags
    resource.body.sub!(/content="text\/html; charset=[^"]+"/, 'content="text/html; charset=UTF-8"')
    # XML
    resource.body.sub!(/encoding="#{from_charset}"/i, 'encoding="UTF-8"')
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
    when 'GET', 'HEAD', 'DELETE', 'OPTIONS', 'TRACE'
      req = Net::HTTP.const_get(m.capitalize).new(path, headers(env))
    when 'PUT', 'POST'
      req = Net::HTTP.const_get(m.capitalize).new(path, headers(env))
      rackreq.body.rewind
      req.body = rackreq.body.read
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

    # fake headers depending on host
    escaped_host = Regexp.escape h['HOST']
    h['REFERER'].sub!(%r{\A(https?://)#{escaped_host}}, "\\1#{@host}") if h['REFERER']

    # do net send hipsterpizza cookies to pizza.de
    if h['COOKIE']
      h['COOKIE'].gsub!(/_hipsterpizza_[^;,\s]+;?/, '')
      h['COOKIE'].strip!
    end

    h['HOST'] = "#{@host}:#{@port}"
    h
  end

  def store
    @store ||= Store.new(host)
  end
end
