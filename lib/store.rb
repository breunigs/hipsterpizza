class Store
  def initialize(host)
    @host = host
  end

  def fetch(env)
    return yield unless storable?(env)

    k = key(env)
    return backend.read(k) if backend.exist?(k)

    r = yield
    if response_successful?(r)
      backend.write(k, r)
    else
      Rails.logger.debug "Cannot store #{k} because response_code=#{response_code(r)}"
    end

    response
  end

  private

  def response_code(response)
    response[0].to_s
  end

  def response_successful?(response)
    response_code(response) == '200'
  end

  def storable?(env)
    env['REQUEST_METHOD'] == 'GET' || Rails.env.test?
  end

  def key(env)
    key = "#{@host}#{env['PATH_INFO']}"
    key << "/#{body_sha(env)}" if env['REQUEST_METHOD'] != 'GET'
    key
  end

  def body_sha(env)
    env['rack.input'].rewind
    Digest::SHA256.hexdigest(env['rack.input'].read)
  end

  def location
    File.join(Rails.root, 'tmp', 'forwarder', @host)
  end

  def backend
    @backend ||= ActiveSupport::Cache::FileStore.new(location)
  end
end
