#!/bin/sh

cd $(dirname $0)
cd ..
wget --quiet -O - "http://www.yrden.de/share/bundler/hipsterpizza.tar.xz" | tar -xJf -
