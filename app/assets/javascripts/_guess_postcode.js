var HIPSTER = (function (my) {
  'use strict';

  var input;

  function checkPostalCode(data) {
    my.log('Reverse Geocoding Result:');
    my.log(data);
    if(my.isInputEmpty(input)) {
      input.val(data.address.postcode);
      input.focus();
    }
  }

  function queryNominatim(pos) {
    var url = 'https://nominatim.openstreetmap.org/reverse?format=json&zoom=18';
    var c = pos.coords;
    var coords = '&lat='+c.latitude+'&lon='+c.longitude;
    my.log('Querying Nominatim at ' + coords);
    $.getJSON(url + coords, checkPostalCode);
  }

  my.guessPostcode = function(input_field) {
    input = $(input_field);

    if(navigator.geolocation && input.length > 0 && my.isInputEmpty(input)) {
      navigator.geolocation.getCurrentPosition(queryNominatim);
    }
  };

  return my;
}(HIPSTER || {}));
