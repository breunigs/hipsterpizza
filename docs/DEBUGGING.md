## Debugging

### Temporarily overwrite third party’s JS

If you want to modify third party JS for testing purposes, ensure you’ve activated HipsterPizza’s caching. If you have not changed the default configuration, you don’t need to change anything.

1. Load the third party site using HipsterPizza once, so all files are cached.
2. Find the file you need in `hipsterpizza/tmp/forwarder/`
4. Open a `rails console` and execute:
```ruby
work_file  = './tmp/working/clean.js'
cache_file = './tmp/forwarder/…/minified.js'

cache_entry      = Marshal.load(File.read(cache_file))
original_request = cache_entry.value
copy_request     = original_request.dup

# save working copy
File.write(work_file, original_request[2][0])

# after each edit to the working copy, run:
File.atomic_write(cache_file) do |f|
  copy_request[2][0] = File.read(work_file)
  cache = ActiveSupport::Cache::Entry.new(copy_request, expires_in: 1.week)
  Marshal.dump(cache, f)
end
```
