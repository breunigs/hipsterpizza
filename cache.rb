
# duration in seconds for which a cache entry is considered valid
CACHE_VALID_TIME = 60*60*5

$cache = {}

def canCache(path)
  return true if path.end_with?(".css")
  return true if path.end_with?(".js")
  return true if path.end_with?(".jpg")
  return true if path.match(/framek[0-9]{3}k.htm$/)
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
  return entry[:content]
end

def writeCache(path, content)
  return unless canCache(path)
  puts "Caching #{path}"
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
