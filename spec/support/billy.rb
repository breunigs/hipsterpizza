# encoding: utf-8

# monkey patching Billy to suit our special need to cache everything
# excluding pages with the /hipster prefix. This means that all requests
# to pizza.de (and other domains) are cached after being processed by
# lib/forwarder.rb and the passthrough_controller.
module Billy
  class Cache
    def cacheable?(url, headers)
      if Billy.config.cache
        url = URI(url)
        !url.path.start_with?('/hipster')
      end
    end
  end
end

Billy.configure do |c|
  c.cache = true
  c.ignore_params = [
    'http://stats.g.doubleclick.net/__utm.gif',
    'http://logc279.xiti.com/hit.xiti',
    'https://apis.google.com/_/+1/fastbutton',
    'https://accounts.google.com/o/oauth2/postmessageRelay'
  ]
  c.persist_cache = true
  c.cache_path = 'tmp/billy-reqs/'
end
