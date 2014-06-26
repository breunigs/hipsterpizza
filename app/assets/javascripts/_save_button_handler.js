//= require jquery_ujs.prompt

$(document).on('ajax:success', '[data-inject-response=true]', function(xhr, data, status) {
  console.log(data);

  if(data['text']) {
    $(this).html(data['text']);
  }

  if(data['error']) {
    alert(data['error']);
  }

  if(data['disable']) {
    console.log('disabling');
    $(this).attr('disabled', 'disabled');
  }

  if(data['reload']) {
    window.location.reload();
  }
});

$(document).on('ajax:error', '[data-inject-response=true]', function(xhr, status, error) {
  $(this).html('error ☹');
  console.log('Broken AJAX: xhr/status/error:');
  console.log(xhr);
  console.log(status);
  console.log(error);
});
