# 2.0 → 2.1

### Important differences:

- HipsterPizza requires Ruby 2.0 or later. Support for 1.9.x has been dropped.
- Default path in docs changed from `/srv/hipsterpizza` to `/var/www/hipsterpizza`. This is only a cosmetic/conventional change only, HipsterPizza runs fine from any directory.
- Location for sample files has changed. If you used symlinks you may need to adjust those.

### Starting fresh

If you decide to start fresh, these files are the files you should save and copy to the new installation:
```
config/fax.yml
config/pinning.yml
db/production.sqlite3
```

You can either use [the manual setup](../README.md#rolling-your-own-copy) like you did before or you can [try your luck using Docker](DOCKER.md).

### Instructions

Unfortunately the instructions given in the old [README.md](../README.md) were incomplete and/or wrong. If you installed HipsterPizza before, you most likely had to execute a different set of commands. This guide tries to take that into account. If you run into problems, please [create a new issue](https://github.com/breunigs/hipsterpizza/issues/new) and I will try to upgrade the guide.

1. Upgrade your system or RVM installation.
  - To upgrade Debian, please [refer to this guide](https://wiki.debian.org/DebianTesting#How_to_use_Debian_.28next-stable.29_Testing).
  - To upgrade RVM, run `rvm update` with the user you use to run HipsterPizza. Next, run `rvm install 2.2.0`. *Note:* Until you update HipsterPizza itself, RVM will try to use Ruby 2.1.2 in the HipsterPizza directory.

  Continue if `ruby --version` outputs `2.0` or higher as the user you run HipsterPizza with.

2. Install additional dependencies:
  ```
  sudo apt-get install ruby bundler git libssl-dev libsqlite3-dev
  ```

3. Update HipsterPizza:

  ```
  cd hipsterpizza && git pull
  ```

  If you have local changes try `git stash && git pull && git stash pop`. If you
  put your changes into a different branch, try: `git checkout master && git pull && git checkout - && git rebase master`.

  If there are any conflicts you have to resolve them manually. You can use `git merge -X theirs` to discard your changes. Use `git reset --hard` to get rid of all your uncommitted changes. If you have significant changes, maybe consider submitting a patch?

4. Update gems / dependencies:
  The command to install the gems has changed previously. You can generally just run `bundle` to pull in new versions as required. However, it is recommended to
  switch to the new method which is least likely to cause conflicts:

  ```
  # (as user that runs HipsterPizza, usually www-data)
  cd hipsterpizza
  rm .bundle/config
  bundle --deployment --without development test
  ```

5. Run HipsterPizza’s housekeeping:
  ```
  RAILS_ENV=production bundle exec rake hipster:setup_production
  ```

6. Restart HipsterPizza.
  - with systemd: `sudo systemctl restart hipsterpizza.service`
  - Otherwise just kill the executable and start it again. The recommended way to do that is `RAILS_ENV=production ./bin/rails server -p 10002 -b localhost`

7. Optional: HipsterPizza now provides a systemd-timer to clean purge old data. Please refer to the [README.md](../README.md#starting-it-automatically) how to install it. If you have previously set up a cronjob it will continue to work.
