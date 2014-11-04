#!/bin/zsh

cd $(dirname $0)
cd ..

source ~/.rvm/scripts/rvm

rvm use 2.1.2
bundle install --without development --deployment --jobs 4

rm -rf vendor/bundle/**/cache/*.gem
rm -rf vendor/bundle/**/nokogiri-*
rm -rf vendor/bundle/**/capybara-webkit-*
tar cf pack_bundler.tar vendor/bundle

# reset to dev mode
bundle install --no-deployment

xz --verbose -9e pack_bundler.tar
rsync --partial --progress "./pack_bundler.tar.xz" vollmar-stefan:/srv/trap/share/bundler/hipsterpizza.tar.xz
