function hipsterAdjustTopBar() {
  $('body').css('padding-top', $('#hipsterTopBar').height() + 'px');
}

$(document).on('ready page:change', hipsterAdjustTopBar);
$(window).resize(hipsterAdjustTopBar);

var isMobileBrowser = (/android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini/i.test(navigator.userAgent.toLowerCase()));
$.fx.off = isMobileBrowser;
