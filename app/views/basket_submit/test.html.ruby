append_raw(@header)
append_raw <<END
  <div id="hipsterTopBar">
    <h1>Streaming Test Page</h1>
  </div>
  <p>
END


%w(This is a simple streaming test. It only works in Rails’ production mode. It should load word by word until this sentence is complete.).each do |word|
  a(word + ' ')
  sleep Rails.env.test? ? 0.05 : 0.5
end


append_raw "</p>"
append_raw(@footer)
