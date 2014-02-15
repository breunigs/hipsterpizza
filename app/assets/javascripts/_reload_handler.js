window.doReload = function() {
  if(window.reloadTimeout) {
    window.clearTimeout(window.reloadTimeout);
  }
  Turbolinks.visit(window.location.href);
};

window.doReloadAfterTimeout = function() {
  var t = document.getElementsByClassName('flash').length == 0 ? 6 : 30;
  window.reloadTimeout = window.setTimeout(window.reloadInplace, t*1000);
}

$(document).on('ajax:success', '[data-auto-reload=true]', function() {
  console.log('Turbolink reloading now');
  window.doReload();
});
