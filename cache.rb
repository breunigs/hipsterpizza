
# duration in seconds for which a cache entry is considered valid
CACHE_VALID_TIME = 60*60*5

$cache = {}

def canCache(path)
  return true if path.end_with?(".css")
  return true if path.end_with?(".js")
  return true if path.end_with?(".jpg")
  return true if path.end_with?(".png")
  return true if path.end_with?(".gif")
  return true if path ==  "/_shop/shopinit_json"
  return true if path.match(/framek[0-9]{3}\.htm$/)
  false
end

def getCache(path)
  entry = $cache[path]
  return nil if entry.nil?

  if isEntryExpired(entry)
    $cache.delete(path)
    return nil
  end

  puts "Used Cache for: #{path}"
  STDOUT.flush
  return entry[:content]
end

def writeCache(path, content)
  return unless canCache(path)
  # only cache successful responses, everything else looks too risky
  return unless content[0].to_s == "200"
  puts "Caching #{path}"
  STDOUT.flush
  $cache[path] = { :expires => Time.now + CACHE_VALID_TIME, :content => content }
end

def sweepCache
  $cache.each do |path, entry|
    if isEntryExpired(entry)
      $cache.delete(path)
      return nil
    end
  end
end

def isEntryExpired(entry)
  Time.now >= entry[:expires]
end
