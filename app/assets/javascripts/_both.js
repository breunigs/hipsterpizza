function hipsterAdjustTopBar() {
  $('body').css('padding-top', $('#hipsterTopBar').height() + 'px');
}

$(document).on('ready page:change', hipsterAdjustTopBar);
$(window).resize(hipsterAdjustTopBar);
