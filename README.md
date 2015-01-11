# HipsterPizza – [pizza.yrden.de](https://pizza.yrden.de)

HipsterPizza allows to make group orders on pizza.de. If you don’t want
to install a copy of HipsterPizza on your own server, you can use the
public instance at **[pizza.yrden.de](https://pizza.yrden.de)**.

## Status

[![Build Status](https://travis-ci.org/breunigs/hipsterpizza.png?branch=master)](https://travis-ci.org/breunigs/hipsterpizza)
[![Test Coverage](https://codeclimate.com/github/breunigs/hipsterpizza/coverage.png)](https://codeclimate.com/github/breunigs/hipsterpizza)
[![Code Climate](https://codeclimate.com/github/breunigs/hipsterpizza.png)](https://codeclimate.com/github/breunigs/hipsterpizza)


## Rolling your own copy

**Manual Setup:** Contine with **Basic Setup** below.

**Docker:** Execute the following and (optionally) continue with [webserver integration](#webserver-integration)
```
git clone git://github.com/breunigs/hipsterpizza
cd hipsterpizza
sudo docker build --tag hipsterpizza .
sudo docker run -d --name hipsterpizza_data -v /var/www/hipsterpizza/db hipsterpizza echo 'HipsterPizza Data Only'
sudo docker run -d --name hipsterpizza_runner --volumes-from hipsterpizza_data -p 10002:10002 hipsterpizza
# Next runs:
# sudo docker stop hipsterpizza_runner
# sudo docker start hipsterpizza_runner
```
Currently there is no HipsterPizza image available for the Docker Registry. I may provide one in the future if people prefer it to making changes in their local git repository.

### Basic Setup
```bash
sudo apt-get install ruby bundler git libssl-dev libsqlite3-dev

sudo mkdir -p /var/www/
sudo chown www-data:www-data /var/www
cd /var/www

# Install HipsterPizza and its dependencies:
sudo -u www-data -s
  git clone git://github.com/breunigs/hipsterpizza
  cd hipsterpizza

  /usr/bin/bundle --deployment --without development test
  ./bin/rake hipster:setup_production

  RAILS_ENV=production ./bin/rails server -p 10002 -b localhost
```

HipsterPizza should now be accessible from your browser at `http://localhost:10002`, give it a spin!

Everything that follows is optional. If you decide that the simple setup is enough for you, you may want to replace `localhost` with `0.0.0.0` in the startup command. Others can access HipsterPizza using your IP or hostname and the port.

### Starting it automatically

**using systemd:**
```
sudo cp /var/www/hipsterpizza/docs/systemd/* /etc/systemd/system/
sudo systemctl enable hipsterpizza.service hipsterpizza-cleanup.timer
sudo systemctl start hipsterpizza.service
```
This will ensure HipsterPizza starts everytime you boot the system. The `hipsterpizza-cleanup` jobs automatically removes outdated data – this keeps the delivery time estimate decent.

**not using systemd:**

Execute the following commands as user `www-data` at appropriate times/events:
```
cd /var/www/hipsterpizza && RAILS_ENV=production ./bin/rails server Puma -p 10002 -b localhost
cd /var/www/hipsterpizza && RAILS_ENV=production ./bin/rake hipster:purge_old
```

## Webserver integration

If you want HipsterPizza to be accessible “properly”, with a real domain and such, you need to install a webserver to act as reverse proxy.

**Caveat:** HipsterPizza does not support sub-URIs/sub-directories. I.e. `pizza.example.com` is fine, while `www.example.com/pizza` is not.

You can find an example config for nginx in [docs/nginx_configuration_example](docs/nginx_configuration_example). It’s strongly recommended to use that as a base. Missing config directives can lead to subtle bugs not immediately visible.

Copy the sample to `/etc/nginx/sites-available/hipsterpizza` and edit the IPv6 address and server name. Add a symbolic link to `sites-enabled` and reload nginx to apply the changes.


## Configuring HipsterPizza to your needs

Once the above setup is done, you should have a public instance of
HipsterPizza running, just like the one on
[pizza.yrden.de](https://pizza.yrden.de).

**config/pinning.yml:**
([see example](config/pinning.example.yml))
Allows you to fixate details you’d need to enter each time when using
HipsterPizza’s public instance. You can prefill only some details or
lock everything down, depending on your needs. Each config options is
documented in the linked example file.

**config/fax.yml:**
([see example](config/fax.example.yml))
If you order regularly from the same delivery service, you can order by
directly sending them a fax (ask them first!). This file allows you to
customize address, logos, etc.

*Biggest advantage:* By
including the nicks with each order, matching pizza box to nerd is speed
up tremendously. If you register with [pdf24.org](https://fax.pdf24.org/),
you can fax from HipsterPizza’s interface, too. This is the setup
[we (Heidelberg’s hacker group)](https://www.noname-ev.de) use. If the
delivery service plays along, this rocks.
