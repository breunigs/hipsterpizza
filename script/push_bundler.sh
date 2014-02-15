#!/bin/zsh

cd $(dirname $0)
cd ..

bundle install --without development --deployment --jobs 4
rm -rf vendor/bundle/**/gems/nokogiri-*/ext/nokogiri/tmp
rm -rf vendor/bundle/**/gems/capybara-webkit-*/src/webkit_server.gch/c++
tar cJf pack_bundler.tar.xz vendor/bundle
rsync --partial --progress "./pack_bundler.tar.xz" vollmar-stefan:/srv/trap/share/bundler/hipsterpizza.tar.xz
