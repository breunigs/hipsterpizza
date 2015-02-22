module CookieHelper
  COOKIE_VALID_KEYS = %w(basket is_admin mode nick replay service)

  def cookie_set(key, value, perma = true)
    key = key.to_s
    raise "invalid cookie key: #{key}" unless cookie_valid_key?(key)

    key = "_hipsterpizza_#{key}"
    if value.nil?
      cookies.delete key
    else
      c = perma ? cookies.permanent : cookies
      c[key] = value.to_s
    end
  end

  def cookie_get(key)
    raise "invalid cookie key: #{key}" unless cookie_valid_key?(key)
    cookies["_hipsterpizza_#{key}"]
  end

  def cookie_delete(key)
    cookie_set(key, nil)
  end

  def cookie_valid_key?(key)
    COOKIE_VALID_KEYS.include?(key.to_s)
  end

  def cookie_debug
    COOKIE_VALID_KEYS.each do |ck|
      logger.debug "COOKIE: #{ck} = #{cookie_get(ck)}"
    end
  end
end
