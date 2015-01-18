class Store
  def initialize(host)
    @host = host
  end

  def fetch(env)
    return yield unless storable?(env)

    expires = { expires_in: guess_expiry(env) }
    k = key(env)
    return backend.read(k) if backend.exist?(k, expires)

    r = yield
    if response_successful?(r)
      backend.write(k, r, expires)
    else
      Rails.logger.debug "Cannot store #{k} because response_code=#{response_code(r)}"
    end

    r
  end

  private

  def response_code(response)
    response[0].to_s
  end

  def response_successful?(response)
    response_code(response) == '200'
  end

  def storable?(env)
    return true if Rails.env.test?
    return false if cache_buster_param?(env)

    env['REQUEST_METHOD'] == 'GET'
  end

  def cache_buster_param?(env)
    !!(env['REQUEST_URI'].to_s =~ /&_=[0-9]{13,}/)
  end

  def key(env)
    key = "#{@host}#{env['REQUEST_URI']}"
    key << "/#{body_sha(env)}" if env['REQUEST_METHOD'] != 'GET'
    key
  end

  def body_sha(env)
    env['rack.input'].rewind
    Digest::SHA256.hexdigest(env['rack.input'].read)
  end

  def guess_expiry(env)
    return 1.week if Rails.env.test?
    return 1.day if env['PATH_INFO'].end_with?(*%w(.js .css .png .jpg))
    1.hour
  end

  def location
    File.join(Rails.root, 'tmp', 'forwarder', @host)
  end

  def backend
    @backend ||= ActiveSupport::Cache::FileStore.new(location)
  end
end
