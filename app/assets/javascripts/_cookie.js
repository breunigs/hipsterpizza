var HIPSTER = (function (my) {
  'use strict';

  // PRIVATE ///////////////////////////////////////////////////////////////////

  function isValidName(name) {
    return (new RegExp('^[a-z-]+$').test(name));
  }

  var COOKIE_PREFIX = '_hipsterpizza_';

  // PUBLIC ////////////////////////////////////////////////////////////////////

  my.getCookie = function(name) {
    name = COOKIE_PREFIX + name + '=';
    var cookies = document.cookie.split(/;\s*/);
    for(var i=0; i< cookies.length; i++) {
      var c = cookies[i];
      if(c.indexOf(name) === 0) {
        var x = c.substring(name.length, c.length);
        return decodeURIComponent(x.split('+').join(' '));
      }
    }
    return null;
  };

  my.setCookie = function(name, value) {
    if(!isValidName(name)) {
      my.err('Cookie Name contains invalid characters');
      return;
    }

    var date;
    if(value === null) {
      // i.e. delete the cookie
      date = 'Thu, 01 Jan 1970 00:00:01 GMT';
    } else {
      var exdate = new Date();
      exdate.setDate(exdate.getDate() + 365);
      date = exdate.toUTCString();
    }
    var data = encodeURIComponent(value) + '; expires=' + date;
    document.cookie = COOKIE_PREFIX + name + '=' + data;
  };


  return my;
}(HIPSTER || {}));
