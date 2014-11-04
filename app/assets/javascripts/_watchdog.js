var HIPSTER = (function (my) {
  'use strict';

  my.Watchdog = function(timeout, callback) {
    if(typeof(callback) !== 'function') {
      throw('Callback must be a function');
    }

    if(typeof(timeout) !== 'number') {
      throw('Timeout must be a number (in seconds)');
    }

    var watchdog = { timeout: timeout, callback: callback, timer: null };

    watchdog.begin = function() {
      this.timer = window.setTimeout(function() {
        my.log(this.timeout + 's have passed without triggering a reset. Running watchdog callback.');
        this.callback();
      }, this.timeout*1000);
    };

    watchdog.end = function() {
      if(this.timer !== null) {
        window.clearTimeout(this.timer);
        this.timer = null;
      }
    };

    return watchdog;
  };

  return my;
}(HIPSTER || {}));
