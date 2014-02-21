append_raw(@header)
append_raw <<END
  <div id="hipsterTopBar">
    <h1>Streaming Test Page</h1>
  </div>
  <p>
END


%w(This is a simple streaming test. It only works in Rails’ production mode. It should load word by word until this sentence is complete.).each do |word|
  # Note: Google Chrome 33+ requires some HTML Tags before actually
  # rerendering. Without them the sentence would only appear once
  # complete.
  append_raw("<span>#{word}</span> ")
  sleep Rails.env.test? ? 0.05 : 0.5
end


append_raw "</p>"
append_raw(@footer)
