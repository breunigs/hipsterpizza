# HipsterPizza

HipsterPizza allows to make group orders on pizza.de. If you don’t want
to install a copy of HipsterPizza on your own server, you can use the
public instance at **[pizza.yrden.de](http://pizza.yrden.de)**.

## Status

[![Build Status](https://travis-ci.org/breunigs/hipsterpizza.png?branch=master)](https://travis-ci.org/breunigs/hipsterpizza)
[![Coverage Status](https://coveralls.io/repos/breunigs/hipsterpizza/badge.png?branch=master)](https://coveralls.io/r/breunigs/hipsterpizza?branch=master)
[![Code Climate](https://codeclimate.com/github/breunigs/hipsterpizza.png)](https://codeclimate.com/github/breunigs/hipsterpizza)


## Rolling your own copy

HipsterPizza uses Rails 4 and has been tested with Ruby 2.1. Here’s how to get it running on Debian stable:
```bash
apt-get install ruby bundler git ruby-sqlite3
cd /srv
git clone git://github.com/breunigs/hipsterpizza
cd hipsterpizza/
su www-data
```

Next, install the required dependencies and run HipsterPizza:
```bash
gem install rake bundler
bundle install
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
upstream hipsterpizza {
    server 127.0.0.1:10002;
}

# used for proper streaming through nginx. Requires nginx 1.3.13+.
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    listen       80;
    listen       [2001:4d88:2000:8::3001]:80 ipv6only=on deferred;
    server_name  pizza.yrden.de;
    access_log   /var/log/nginx/hipsterpizza.log;
    root         /srv/hipsterpizza/public;

    # serve assets directly from the file system
    location ~ ^/hipster/assets/  {
        gzip_static on;
        expires max;
        add_header Cache-Control public;
    }

    location / {
        proxy_pass http://hipsterpizza;
        proxy_set_header  X-Real-IP  $remote_addr;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
        # ensure redirects keep the same protocol (i.e. no https → http)
        proxy_set_header  X-Url-Scheme $scheme;
        proxy_set_header  X-Forwarded-Proto $scheme;
        proxy_set_header  Host $http_host;
        proxy_redirect    off;

        # required for proper streaming. Requires nginx 1.3.13+
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
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



## Configuring HipsterPizza to your needs

Once the above setup is done, you should have a public instance of
HipsterPizza running, just like the one on
[pizza.yrden.de](http://pizza.yrden.de).

**config/pinning.yml:**
([see example](https://github.com/breunigs/hipsterpizza/blob/master/config/pinning.example.yml))
Allows you to fixate details you’d need to enter each time when using
HipsterPizza’s public instance. You can prefill only some details or
lock everything down, depending on your needs. Each config options is
documented in the linked example file.

**config/fax.yml:**
([see example](https://github.com/breunigs/hipsterpizza/blob/master/config/fax.example.yml))
If you order regularly from the same delivery service, you can order by
directly sending them a fax (ask them first!). This file allows you to
customize address, logos, etc.

*Biggest advantage:* By
including the nicks with each order, matching pizza box to nerd is speed
up tremendously. If you register with [pdf24.org](https://fax.pdf24.org/),
you can fax from HipsterPizza’s interface, too. This is the setup
[we (Heidelberg’s hacker group)](https://www.noname-ev.de) use. If the
delivery service plays along, this rocks.
