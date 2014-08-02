var isMobileBrowser = (/android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini|capybara/i.test(navigator.userAgent.toLowerCase()));

// turn off any FX because they are too slow on mobile the way they are
// implemented (probably better in newer jQuery versions, but those are
// not used by pizza.de)
$.fx.off = isMobileBrowser;

function hipsterGetCookie(name) {
  'use strict';

  name = '_hipsterpizza_' + name + '=';
  var cookies = document.cookie.split(/;\s*/);
  for(var i=0; i< cookies.length; i++) {
    var c = cookies[i];
    if(c.indexOf(name) === 0) {
      var x = c.substring(name.length, c.length);
      return decodeURIComponent(x.split('+').join(' '));
    }
  }
  return null;
}

function hipsterSetCookie(name, value) {
  'use strict';

  if(!(new RegExp('^[a-z-]+$').test(name))) {
    err('Cookie Name contains invalid characters');
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
  var data = encodeURIComponent(value) + "; expires=" + date;
  document.cookie = "_hipsterpizza_" + name + "=" + data;
}
