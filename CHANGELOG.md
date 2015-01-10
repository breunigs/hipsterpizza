## 2.0.1 (unreleased)

Maintenance release, with little visible changes. For details on how to upgrade, [UPGRADING.md](please see UPGRADING.md).

User-Facing:

  - reworked and translated privacy page

Under the Hood:

  - update dependencies (gems)
  - improved tests: Previously only system tests were used. However, those were often failing/flapping and rather slow.
  - added binstubs: you can use them instead of prepending `bundle exec`. E.g. `./bin/rspec` to run all tests. If you install [direnv](https://github.com/zimbatm/direnv), your `PATH` is updated automatically, too.

## 2.0.0

Previously HipsterPizza had a rolling release, opposed to the semantic versioning used now. The last “unversioned” change was [6a6cf91dc](https://github.com/breunigs/hipsterpizza/commit/6a6cf91dc1529d8ce319383bc5a9967d6ddae61d), authored 2015-01-04.

## 1.0

See [v1 branch in repository](https://github.com/breunigs/hipsterpizza/tree/v1) for details.
