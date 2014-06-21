window.refreshWithAjax = function() {
  'use strict';

  function refresh() {
    var params = '?ts_basket=' + window.lastUpdates.basket;
    params += '&ts_order=' + window.lastUpdates.order;

    $.ajax(window.location.href + '.js' + params, {
      dataType: 'script',
      complete: timeout,
    });
  }

  function timeout() {
    window.setTimeout(refresh, 10*1000);
  }

  timeout();
};
