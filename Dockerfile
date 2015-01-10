FROM debian:testing
MAINTAINER Stefan Breunig <stefan-hipsterpizza@yrden.de>

RUN apt-get update && apt-get install -y --force-yes --no-install-recommends \
  build-essential \
  git \
  libssl-dev \
  libsqlite3-dev \
  ruby \
  ruby-dev

WORKDIR /var/www/hipsterpizza

RUN gem install bundler --no-ri --no-rdoc
ADD Gemfile* /var/www/hipsterpizza/
RUN /usr/local/bin/bundler --jobs 4 --deployment --without development test

ADD . /var/www/hipsterpizza/
RUN chown --recursive www-data:www-data /var/www/

ADD docs/systemd/hipsterpizza-cleanup* /etc/systemd/system/
RUN systemctl enable hipsterpizza-cleanup.timer

USER www-data
# Needs to run again to fix up gem detection?
RUN /usr/local/bin/bundler --jobs 4 --deployment --without development test --quiet
RUN ./bin/rake hipster:setup_production

ENV RAILS_ENV production
EXPOSE 10002
CMD ./bin/rails server -p 10002 -b 0.0.0.0
