//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require _both
//= require _save_button_handler
//= require _reload_handler

$(document).on('page:load page:restore ready', function() {
  $('#setNickForm').submit(function() {
    var form = $(this);
    var nick = form.find('input[name=nick]').val();
    hipsterSetCookie('nick', nick);
    console.log('nick=' + hipsterGetCookie('nick'));
    form.trigger('reload:now');
    return false;
  });

});

Turbolinks.enableTransitionCache();
