HipsterPizza
============

HipsterPizza allows making group orders with any pizza.de shop.

Same thing in German, so it may be found by search engines:
Mit HipsterPizza können Gruppenbestellungen bei jedem Anbieter auf
pizza.de gemacht werden.



Usage
-----

HipsterPizza shows an overview page by default. It lists each person’s
orders along with the price and if they put money on the money pile.
Clicking the “make new order” button takes the user to the shop’s
pizza.de page with only a few things changed. The order will obviously
not be submitted to the store directly, but rather land in the combined
basket.

Orders can be saved or copied (“cp”). If the user has cookies enabled,
she may also delete her own order. Editing an order is currently not
possible, unless you copy it first, change it and delete the old one.

The admin features are hidden, so they are not clicked accidentally. You
need to scroll down all the way and then put your cursor on the bottom
center part of the page. *SuperPowers Activate* allows you to delete any
order. *I will pay for everyone* initiates the group order.

Caveats:
- tool allows only one order per day
- replaying saved orders and initiating the group order does **not** work
  in Opera for some reason. Firefox and Chrome are fine.
- replaying will likely hang your browser. Be patient.


Screen
------

---
![Overview Page](http://b.uni-hd.de/hipsterpizza/overview.png)

---



Requirements
------------

You’ll need a server which runs Ruby 1.9.2+ and Apache/nginx. If you’re
using Debian, have at least the following packages installed:
`ruby1.9.1 ruby-sqlite3 ruby-rack`


Setup
-----

1. If you can run `rackup -s thin` and don’t get an error, it means you
can successfully run HipsterPizza. You’ll need to install *prawn*,
either by `apt-get install ruby-prawn` or `gem install prawn`.
2. Adjust your public URL and the shop you want to use in `config.ru`.
  - The public URL is where HipsterPizza will later be available for
 everyone. If you don’t have an own domain or want it only to be
 available locally it will probably be `http://localhost:9292`.
  - You can find out the shop URL by visiting it via pizza.de. Hover any
    link – that’s the URL you’re looking for. Note that this is NOT the
    URL which is displayed in the browser.
  - You can also only allow orders on a certain week day, if you want.
    This is not enforced however, so someone who knows the URL can still
    place orders.
3. Set your contact info which will be sent to the delivery service in
   `hipster-delivery-data.json`. There’s a template available in
   `hipster-delivery-data.json-template` that you can copy.
4. You can integrate HipsterPizza any way you like into your server
   landscape. We’re using a reverse lookup because it’s easy to set up
   and HipsterPizza won’t be high traffic anyway.
  - run `./boot.sh` in a screen session
  - in `/etc/nginx/sites-enabled/hipsterpizza`:

            server {
                listen YOUR_V4_IP:80;
                listen YOUR_V6_IP:80;

                keepalive_timeout 60;

                root /path/to/your/hipsterpizza/;
                access_log /var/log/nginx/hipsterpizza-access.log combined;
                error_log /var/log/nginx/hipsterpizza-error.log;
                index index.html index.htm;

                server_name SAME_AS_OUR_HOST;

                location / {
                    proxy_pass http://localhost:9292;
                }
            }


Using your own fax
------------------

#### Why?

- fax includes nicks, so if the vendor plays along it’s much easier to match pizza to person
- pizza.de doesn’t take 10%+ from your pizza service
- you can fax your cool logo

It’s probably a good idea to ask your vendor first if it’s okay if you submit this way. HipsterPizza includes the scraped prices and a sum and not everyone might trust you on that.

##### How?

This highly depends on what fax solution you want to employ. First, setup your solution to be able to fax PDF files. After that you can incorporate HipsterPizza using these three URLs:
```
…?action=getfaxnumber       retrieve vendor’s fax number
…?action=marksubmitted      block further orders
…?action=genpdf             PDF file with the orders
```

**Using pdf24.org:** Most likely the easiest way to get this running is by making an account at pdf24.org. As far as I can tell, the ads are negligible and it’s free if you only send a few pages a month. You’ll need `apt-get install phantomjs w3m w3m-img && gem install casperjs` and adjust the configuration in `custom_fax/pdf24fax.js` after creating an account on pdf24.org. Use `custom_fax/pdf24fax_wrapper.sh` to send the faxes.

**Using a FritzBox:** If you own a FritzBox, you can most likely use it to send faxes. The sample script in `custom_fax/fritz_box_fax.sh` uses Roger Router (formerly known as ffgtk) to talk to your FritzBox.

Also, don’t forget to adjust your logo in `images/faxlogo.png`.

License and attribution
-----------------------

HipsterPizza is licensed under der ISC license. Parts imported from
other projects remain under their respective license:

- images/logosml.png glasses by Marco Papa, from The Noun Project, CC-BY 3.0
- images/logo.png by Kyle Scott, from The Noun Project, CC-BY 3.0
- bootstrap.min.css by Twitter, Inc, Apache License 2.0
- reverse_proxy.rb from rack-reverse-proxy by jaswope, MIT

See `ATTRIBUTION` for details.
