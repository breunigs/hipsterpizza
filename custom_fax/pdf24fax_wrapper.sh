#!/bin/sh

echo "If you have missing software, run:"
echo "apt-get install phantomjs w3m w3m-img && gem install casperjs"
echo "\n\n"

LC_ALL=en_US casperjs pdf24fax.js
