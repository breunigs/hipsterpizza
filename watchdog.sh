#!/bin/sh

ROOT="$(pwd)"



cd $ROOT

if [ ! -f rack.pid ]; then
  echo "PID file not found, booting service"
  ./boot.sh&
  exit 0
fi


kill -0 $(cat rack.pid)
if [ $? -ne 0 ]; then
  echo "PID file found, but service not running"
  ./boot.sh&
  exit 0
fi

exit 0
