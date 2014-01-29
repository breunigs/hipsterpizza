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

    var date;
    if(value === null) {
      // i.e. delete the cookie
      date = 'Thu, 01 Jan 1970 00:00:01 GMT';
    } else {
      var exdate = new Date();
      exdate.setDate(exdate.getDate() + 365);
      date = exdate.toUTCString();
    }
    var data = escape(value) + "; expires=" + date;
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
      // subitems = additional toppings, subsubitems = salad dressing in menus
      var finder = ".cartitems-subitem .cartitems-subtitle a, .cartitems-subsubitem .cartitems-subtitle a"
      $(elm).find(finder).each(function(ind, ingred) {
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

  function findLinkWithText(text) {
    return $('a').filter(function() { return $(this).text() === text; });
  }

  function getPriceOfLastItem() {
    var p = $(".cartitems:last .cartitems-itemsum .cartitems-sprice div").text();
    p = $.trim(p).replace(/\s.*$/, "").replace(",", ".");
    return parseFloat(p);
  }

  function getActiveSubPageText() {
    return $(".navbars a.activ").text();
  }

  function replay(items, finishCallback) {
    // setup
    log("replay: setup started");
    $.fx.off = true;
    $("body").addClass("wait");
    var navLinks = $.makeArray($(".navbars a"));
    var currentNav = null;
    var errorMsgs = [];

    // loads the next sub page in the nav links array.
    function loadNextSubPage() {
      log("replay: loading next subpage");
      currentNav = $(navLinks.shift());
      // if an element has this class, the pizza.de JS code avoids
      // loading it. Therefore remove it to ensure the content_ready
      // event fires.
      currentNav.removeClass('activ');
      currentNav.click();
      return true;
    }

    // searches current sub page and adds found items to basket. The
    // items get removed from the "to go" list
    function addItemsToBasket() {
      log("replay: searching page “" + getActiveSubPageText() + "” for items");

      items = $.grep(items, function (item, ind) {
        var link = findLinkWithText(item["prod"]);
        if(link.length === 0) return true; // not found; keep in queue
        if(link.length >= 2) {
          console.warn("ITEM #"+ind+" AMBIGUOUS: " + item["prod"]);
          // keep item, so it may be added manually later
          return true;
        }

        log("replay: found item “" + item["prod"] + "”");

        var errmsg = "product="+item["prod"]+"  | ";
        // exactly one link found. Add it to cart or open extra
        // ingredients popup. If an item can't have extra ingredients
        // this will immediately put the item in the cart.
        link.click();
        // add extra ingredients, if any.
        $.each(item["extra"], function(ind, extra) {
          // .shop-dialog == the popup
          // .dlg-nodes-addition == the "add items part". Required if
          // an ingredient should be added multiple times. Otherwise
          // the remove item link would be catched as well.
          var ingred = $(".shop-dialog .dlg-nodes-addition a:contains('"+extra+"')");
          if(ingred.length === 0) {
            console.warn(errmsg + " EXTRA NOT FOUND: " + extra);
          } else if(ingred.length >= 2) {
            console.warn(errmsg + " EXTRA AMBIGUOUS: " + extra);
          } else {
            ingred.click();
          }
        });
        // If there was an extra ingredients popup: close it and put
        // finalized item into cart.
        // If there wasn't an extra igredients popup; will not match
        // anything and thus not execute.
        $(".shop-dialog a:contains('in den Warenkorb'):first").click();

        // comparing prices as sanity check
        if(getPriceOfLastItem() !== item["price"]) {
          var msg = errmsg + "Prices do not match. Expected: " + item["price"] + "   Actual price: " + getPriceOfLastItem();
          console.warn(msg);
          errorMsgs.push(msg);
        }

        // remove item from list
        return false;
      });
    }


    // this function does the actual work of finding the items and adding
    // them to the basket. Because the category sub pages are loaded by
    // asynchronous JavaScript magic it's not possible to simply loop
    // over all categories. Instead, this function is called once to load
    // a new subpage and exit. It is called again by listening to changes
    // in the webpage (see below). In this call it iterates over all items
    // which still need to be found and adds them to the basket. It also
    // resets the current category and executes again in a bit. This
    // repeats until all items are found or there are no more sub pages.
    function process() {
      if(items.length === 0 || (currentNav === null && navLinks.length === 0))
        return tearDown();

      if(currentNav === null) {
        loadNextSubPage();
      } else {
        // reset sub page
        currentNav = null;
        addItemsToBasket();
        // continue with next step
        process();
      }
    }

    function tearDown() {
      log('replay: tear down');
      $('#inhalt').unbind('content_ready', process);
      $("body").removeClass("wait");
      $("#hipsterProgress").hide();
      $.fx.off = false;
      // only ever replay once
      setCookie('replay', null);

      if(typeof finishCallback === 'function') {
        log('replay: running callback');
        finishCallback(errorMsgs);
      }
    }

    // listen to the same event as pizza.de for content loading
    $('#inhalt').bind('content_ready', process);

    // start processing
    process();
  }

  function getSubmitButton() {
    return $('#hipsterOrderSubmitButton');
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
      var form = getSubmitButton().parents('form');
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
    },

    replayData: function() {
      var data = window.hipsterReplayData;
      var mode = window.hipsterReplayMode;
      if(typeof data === 'undefined' || data === null) {
        return;
      }

      switch(mode) {
        case 'check':
          replay(data, function(err) {
            if(err.length === 0) return;
            alert('There have been errors replaying the data: \n' + err.join('\n'));
          });
          break;

        case 'nocheck':
          replay(data);
          break;

        case 'insta':
          replay(data, function() { getSubmitButton().click(); });
          break;

        default:
          err('Invalid replay mode, no action taken');
      }
    }
  };
})();


hipster.disableAreaCodePopup();


hipster.runAfterLoad(function() {
  hipster.detectAndSetShop();
  hipster.hideOrderFieldsAppropriately();
  hipster.bindSubmitButton();
  hipster.replayData();
});
