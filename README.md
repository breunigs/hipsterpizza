# HipsterPizza

HipsterPizza allows to make group orders on pizza.de. If you don’t want
to install a copy of HipsterPizza on your own server, you can use the
public instance at **[pizza.yrden.de](http://pizza.yrden.de)**.

## Status

[![Build Status](https://travis-ci.org/breunigs/hipsterpizza.png)](https://travis-ci.org/breunigs/hipsterpizza)
[![Coverage Status](https://coveralls.io/repos/breunigs/hipsterpizza/badge.png)](https://coveralls.io/r/breunigs/hipsterpizza?branch=v2)
[![Code Climate](https://codeclimate.com/github/breunigs/hipsterpizza.png)](https://codeclimate.com/github/breunigs/hipsterpizza?branch=v2)


## Rolling your own copy

HipsterPizza uses Rails 4 and has been tested with Ruby 2.1. Here’s how to get it running on Debian stable:
```bash
apt-get install ruby bundler git ruby-sqlite3
cd /srv
git clone -b v2 git://github.com/breunigs/hipsterpizza
cd hipsterpizza/
su www-data
```

Next, install the required dependencies and run HipsterPizza:
```bash
gem install rake bundler
rake hipster:setup_production
```

You are almost done, now. HipsterPizza assumes you are going to run it
behind nginx, Apache or another web server. If you **don’t**, set
```ruby
# in /srv/hipsterpizza/config/environments/production.rb
config.serve_static_assets = true
```
to `true`, otherwise the assets won’t be served.

Here’s an example config for nginx:
```
upstream puma-hipsterpizza {
    server 127.0.0.1:10002;
}

server {
    listen       80;
    listen       [2001:4d88:2000:8::3001]:80 ipv6only=on deferred;
    server_name  pizza.yrden.de;
    access_log   /var/log/nginx/pizza.yrden.de.log;
    root         /srv/hipsterpizza/public;

    location ~ ^/hipster/assets/  {
        gzip_static on;
        expires max;
        add_header Cache-Control public;
    }

    location / {
        proxy_pass http://puma-hipsterpizza;
        proxy_set_header  X-Real-IP  $remote_addr;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header  Host $http_host;
        proxy_redirect    off;
    }
}
```

Finally, set up a cron job to execute the following command:
```
RAILS_ENV=production ./bin/rake hipster:purge_old
```

This ensures old and outdated data is removed, which keeps the users’
privacy and ensures the estimate calculations are based on somewhat
recent orders.
