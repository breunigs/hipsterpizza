class Store
  def initialize(host)
    @host = host
  end

  def fetch(env, &block)
    return block.call unless storable?(env)

    k = key(env)
    return backend.read(k) if backend.exist?(k)

    r = block.call
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
    env['REQUEST_METHOD'] == 'GET'
  end

  def key(env)
    "#{@host}#{env['PATH_INFO']}"
  end

  def location
    File.join(Rails.root, 'tmp', 'forwarder', @host)
  end

  def backend
    @backend ||= ActiveSupport::Cache::FileStore.new(location)
  end
end
