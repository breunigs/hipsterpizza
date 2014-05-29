module CookieHelper
  def cookie_set(key, value, perma = true)
    raise "invalid cookie key: #{key}" unless cookie_valid_key?(key)

    key = "_hipsterpizza_#{key}"
    if value.nil?
      cookies.delete key
    else
      c = perma ? cookies.permanent : cookies
      c[key] = value
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
    %w(basket is_admin mode nick replay).include?(key.to_s)
  end
end
