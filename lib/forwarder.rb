# encoding: utf-8

# via https://gist.github.com/chneukirchen/32376

require 'net/http'
require 'rack'

class Forwarder
  def initialize(host, port=80)
    @host, @port = host, port
  end

  def call(env)
    rackreq = Rack::Request.new(env)

    headers = Rack::Utils::HeaderHash.new
    env.each do |key, value|
      headers[$1] = value if key =~ /HTTP_(.*)/
    end

    headers["HOST"] = "#{@host}:#{@port}"

    res = Net::HTTP.start(@host, @port) { |http|
      m = rackreq.request_method
      path = rackreq.fullpath.blank? ? "/" : rackreq.fullpath

      case m
      when "GET", "HEAD", "DELETE", "OPTIONS", "TRACE"
        req = Net::HTTP.const_get(m.capitalize).new(path, headers)
      when "PUT", "POST"
        req = Net::HTTP.const_get(m.capitalize).new(path, headers)
        req.body_stream = rackreq.body
      else
        raise "method not supported: #{method}"
      end

      http.request(req)
    }

    res_hash = res.to_hash
    fix_encoding!(res, res_hash)

    [res.code, Rack::Utils::HeaderHash.new(res_hash), [res.body]]
  end

  private

  def guess_charset(res_hash)
    Rails.logger.warn res_hash["content-type"].join(" ")
    res_hash["content-type"].join(" ").match(/charset=([^\s]+)/)[1] rescue nil
  end

  def fix_encoding!(resource, res_hash)
    charset = guess_charset(res_hash)
    return unless charset
    resource.body.encode!('utf-8', charset, invalid: :replace, undef: :replace, :replace => '♥') if charset != "utf-8"
  end
end
