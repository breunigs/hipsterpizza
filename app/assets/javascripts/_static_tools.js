var HIPSTER = (function (my) {
  'use strict';

  // PRIVATE ///////////////////////////////////////////////////////////////////
  // PUBLIC ////////////////////////////////////////////////////////////////////

  my.log = function() {
    if(window.console && window.console.log) {
      // window.console.log(arguments);
      window.console.log.apply(window.console, arguments);
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
    return my.getCookie('mode');
  };

  my.textPriceToFloat = function(text) {
    return parseFloat(text.replace(/\s/g, '').replace(',', '.'));
  };

  my.isInputEmpty = function(input) {
      return $.trim(input.val()) === '';
  };

  my.isBlank = function(input) {
    if(typeof input === 'undefined' || input === null || input === '') return true;
    if(typeof input === 'string' && input.match(/^\s+$/)) return true;
    return false;
  };

  return my;
}(HIPSTER || {}));
