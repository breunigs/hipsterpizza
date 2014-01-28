//= require jquery_ujs

var hipster = window.hipster = (function() {
  // CACHES ////////////////////////////////////////////////////////////
  var _isShop = null;
  var _isLoading = true;
  var _runAfterLoad = [];

  // PRIVATE ///////////////////////////////////////////////////////////
  function log(text) {
    if(window.console && window.console.log) {
      window.console.log(text);
    }
  }

  function err(text) {
    if(window.console && window.console.error) {
      window.console.error(text);
    } else {
      alert(text);
    }
  }

  function getCookie(name) {
    name = '_hipsterpizza_' + name + '=';
    var cookies = document.cookie.split(/;\s*/);
    for(var i=0; i< cookies.length; i++) {
      c = cookies[i];
      if(c.indexOf(name) === 0) {
        return unescape(c.substring(name.length, c.length));
      }
    }
    return null;
  }

  function setCookie(name, value) {
    if(!(new RegExp('^[a-z-]+$').test(name))) {
      err('Cookie Name contains invalid characters');
      return;
    }

    var exdate = new Date();
    exdate.setDate(exdate.getDate() + 365);
    var data = escape(value) + "; expires=" + exdate.toUTCString();
    document.cookie = "_hipsterpizza_" + name + "=" + data;
  }

  function getCurrentAction() {
    return getCookie('action');
  }

  function isShopPage() {
    if(_isShop !== null) return _isShop;

    _isShop = $('body:contains("Warenkorb")').length === 1;
    return _isShop;
  }

  function isLoading() {
    if(!_isLoading) {
      return false;
    }

    _isLoading = $('label:contains("PLZ")').length === 0;
    return _isLoading;
  }

  function getCartItemsJson() {
    var data = [];
    $(".cartitems").each(function(ind, elm) {
      var prod = $(elm).find(".cartitems-title div").text();
      var price = $(elm).find(".cartitems-itemsum .cartitems-sprice div").text();
      price = parseFloat(price.replace(/\s/, "").replace(",", "."));

      if($.trim(prod) === "" || isNaN(price)) {
        err("Couldn't detect product properly, maybe the script is broken?");
        return;
      }

      var extra = [];
      $(elm).find(".cartitems-subitem .cartitems-subtitle a").each(function(ind, ingred) {
        extra[ind] = $(ingred).text();
      });

      data[ind] = { "price": price, "prod": prod, "extra": extra.sort() };
    });
    return data;
  }

  function getUserNick() {
    var nick = getCookie('nick');
    do {
      nick = prompt('Your Nick:', nick === null ? '' : nick);
      // user clicked cancel
      if(nick === null) {
        return null;
      }
    } while(nick === '');
    setCookie('nick', nick);
    return nick;
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
    hideOrderFieldsAppropriately: function() {
      if(getCurrentAction() === 'submit_group_order') {
        log('Not hiding address fields because we want to submit the group basket');
        return;
      }

      $('body').addClass('hideOrderFields');
    },

    disableAreaCodePopup: function() {
      if(!window.cart) {
        return;
      }

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
      var button = $('#hipsterShopChooser');
      button.val('Choose ' + hipster.getShopName());

      var hidden = $('#hipsterShopCanonicalUrl');
      hidden.val($("link[rel=canonical]").attr('href'));

      hidden = $('#hipsterShopName');
      hidden.val(hipster.getShopName());

      button.show();
    },

    bindSubmitButton: function() {
      var form = $('#hipsterOrderSubmitButton').parents('form');
      form.submit(function() {
        var items = getCartItemsJson();
        if(items.length === 0) {
          alert('You need to select at least one item.');
          return false;
        }
        $('#hipsterOrderJson').val(JSON.stringify(items));

        var nick = getUserNick();
        if(nick === null) {
          // user clicked cancel in dialog, abort
          return false;
        }
        $('#hipsterOrderNick').val(nick);
      });
    }
  };
})();


hipster.disableAreaCodePopup();


// für das replay später
//$('#inhalt').bind('content_ready', function() {

hipster.runAfterLoad(function() {
  hipster.detectAndSetShop();
  hipster.hideOrderFieldsAppropriately();
  hipster.bindSubmitButton();
});
