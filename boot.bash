#!/bin/bash

dir=$(dirname $(readlink -f $0))
cd "${dir}"
rackup -s thin &> "${dir}/access.log"
