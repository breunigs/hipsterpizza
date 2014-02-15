#!/bin/sh

cd $(dirname $0)
cd ../tmp/capybara

echo
echo

for i in *.png; do
  echo $i
  url=$(base64 --wrap=0 $i | curl --silent -F 'sprunge=<-' http://sprunge.us)
  echo "wget -qO - $url | base64 --decode | display"
  echo
done
