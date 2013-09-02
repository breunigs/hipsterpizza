#!/bin/bash

dir=$(dirname $(readlink -f $0))
cd "${dir}"
nohup rackup -s thin -o 127.0.0.1 -p 9292 -P rack.pid > "${dir}/access.log"
