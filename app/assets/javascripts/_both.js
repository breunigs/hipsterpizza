function hipsterAdjustTopBar() {
  $('body').css('padding-top', $('#hipsterTopBar').height() + 'px');
}

$(document).on('ready page:change', hipsterAdjustTopBar);
$(window).resize(hipsterAdjustTopBar);

var isMobileBrowser = (/android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini/i.test(navigator.userAgent.toLowerCase()));
$.fx.off = isMobileBrowser;



function hipsterGetCookie(name) {
  name = '_hipsterpizza_' + name + '=';
  var cookies = document.cookie.split(/;\s*/);
  for(var i=0; i< cookies.length; i++) {
    c = cookies[i];
    if(c.indexOf(name) === 0) {
      return decodeURIComponent(c.substring(name.length, c.length));
    }
  }
  return null;
}

function hipsterSetCookie(name, value) {
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
