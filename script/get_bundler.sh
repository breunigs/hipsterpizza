#!/bin/sh

cd $(dirname $0)
cd ..
wget --quiet -O - "http://www.yrden.de/share/bundler/hipsterpizza.tar.xz" | tar -xJfv -

# if the server is down or the file corrupt, contine install normally
exit 0

