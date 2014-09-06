var HIPSTER = (function (my) {
  'use strict';

  // PRIVATE ///////////////////////////////////////////////////////////////////
  // PUBLIC ////////////////////////////////////////////////////////////////////

  my.log = function(text) {
    if(window.console && window.console.log) {
      window.console.log(text);
    }
  };

  my.err = function(text) {
    if(window.console && window.console.error) {
      window.console.error(text);
    } else {
      window.alert(text);
    }
  };

  my.getCurrentMode = function() {
    return hipsterGetCookie('mode');
  };

  my.textPriceToFloat = function(text) {
    return parseFloat(text.replace(/\s/g, '').replace(',', '.'));
  };

  my.isInputEmpty = function(input) {
      return $.trim(input.val()) === '';
  };

  return my;
}(HIPSTER || {}));
