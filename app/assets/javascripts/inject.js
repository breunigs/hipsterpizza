//= require jquery_ujs

var hipster = window.hipster = (function() {
  // CACHES ////////////////////////////////////////////////////////////
  var _isShop = null;
  var _isLoading = true;
  var _runAfterLoad = [];

  // PRIVATE ///////////////////////////////////////////////////////////
  function isShopPage() {
    if(_isShop !== null) return _isShop;

    _isShop = $('body:contains("Warenkorb")').length === 1;
    return _isShop;
  }

  function isLoading() {
    if(!_isLoading) {
      return false;
    }

    _isLoading = $("label:contains('PLZ')").length === 0;
    return _isLoading;
  }


  var MutationObserver = window.MutationObserver || window.WebKitMutationObserver;
  var waitForLoad = new MutationObserver(function(mutations, observer) {
      if(isLoading()) {
        return;
      }
      observer.disconnect();
      for(var i = 0; i < _runAfterLoad.length; i++) {
        _runAfterLoad[i]();
      }
      _runAfterLoad = null;
  });
  waitForLoad.observe(window.document, { childList: true, subtree: true });

  // PUBLIC ////////////////////////////////////////////////////////////
  return {
    //~　isFrame: function() {
      //~　return window.self !== window.top;
    //~　},

    disableAreaCodePopup: function() {
      // URLs without &knddomain=1 switch
      window.cart.check4DeliveryArea = function() {}
      // URLs with that switch
      window.cart.config.behavior.checkDeliveryAreaOnCustDomains = 0;
    },

    runAfterLoad: function(func) {
      if(!isLoading()) {
        func();
        return;
      }
      _runAfterLoad.push(func);
    },

    getShopName: function() {
      if(!isShopPage()) {
        return null;
      }

      return $("title").text();
    },

    detectAndSetShop: function() {
      var button = $(".hipsterProviderName");
      button.val("Choose " + hipster.getShopName());

      var hidden = $("#hipsterProviderCanonicalUrl");
      hidden.val($("link[rel=canonical]").attr("href"));

      button.show();
    }
  };
})();


hipster.disableAreaCodePopup();


// für das replay später
//$('#inhalt').bind('content_ready', function() {

hipster.runAfterLoad(function() {
  hipster.detectAndSetShop();

});
