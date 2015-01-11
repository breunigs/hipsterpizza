#!/bin/zsh

cd $(dirname $0)
cd ..

source ~/.rvm/scripts/rvm

rvm use $(cat .ruby-version)
bundle install --without development --deployment --jobs 4

rm -rf vendor/bundle/**/cache/*.gem
rm -rf vendor/bundle/**/nokogiri-*
tar cf pack_bundler.tar vendor/bundle

# reset to dev mode
rm .bundle/config
rm -rf vendor/bundle
bundle install --no-deployment --jobs 4&

xz --verbose -9e pack_bundler.tar
rsync --partial --progress "./pack_bundler.tar.xz" vollmar-stefan:/srv/trap/share/bundler/hipsterpizza.tar.xz

rm pack_bundler.tar.xz
wait
