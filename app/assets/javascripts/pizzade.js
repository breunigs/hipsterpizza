//= require jquery_ujs
//= require _both

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

  function getCurrentAction() {
    return hipsterGetCookie('action');
  }

  function getPostalCode() {
    var input = $('#plzsearch_input');

    function isInputEmpty() {
      return $.trim(input.val()) === '';
    }

    function checkPostalCode(data) {
      log('Reverse Geocoding Result:');
      log(data);
      if(isInputEmpty()) {
        input.val(data['address']['postcode']);
        input.focus();
      }
    }

    function queryNominatim(pos) {
      var url = 'http://nominatim.openstreetmap.org/reverse?format=json&zoom=18';
      var c = pos.coords;
      var coords = '&lat='+c.latitude+'&lon='+c.longitude;
      console.log('Querying Nominatim at ' + coords);
      $.getJSON(url + coords, checkPostalCode);
    }



    if(navigator.geolocation && input.length > 0 && isInputEmpty()) {
      navigator.geolocation.getCurrentPosition(queryNominatim);
    }
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

  function getShaAddress() {
    var prefix = 'hipsterpizza_odr_';
    // keep in sync with basket_helper#contact_sha_address
    var addr = '';
    addr += localStorage[prefix + 'zipcode'] + ' ';
    addr += localStorage[prefix + 'street'] + ' ';
    addr += localStorage[prefix + 'street_no'];
    addr = $.trim(addr).toLowerCase().replace(/[^a-z0-9]/g, '');

    if(addr === '') {
      return null;
    }

    return new jsSHA(addr, "TEXT").getHash("SHA-512", "HEX");
  }

  function textPriceToFloat(text) {
    return parseFloat(text.replace(/\s/g, "").replace(",", "."));
  }

  function getCartItemsJson() {
    var data = [];
    $(".cartitems").each(function(ind, elm) {
      var prod = $(elm).find(".cartitems-title div").text();
      var price = $(elm).find(".cartitems-itemsum .cartitems-sprice div").text();
      price = textPriceToFloat(price);

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

    var deposit = textPriceToFloat($(".deposit div").text());
    if(!isNaN(deposit) && deposit > 0) {
      data[data.length] = { price: deposit, "prod": "Pfand", extra: [] };
    }

    return data;
  }

  function getUserNick() {
    var nick = hipsterGetCookie('nick');
    do {
      nick = prompt('Your Nick:', nick === null ? '' : nick);
      // user clicked cancel
      if(nick === null) {
        return null;
      }
    } while(nick === '');
    hipsterSetCookie('nick', nick);
    return nick;
  }

  function findLinkWithText(text) {
    return $('#framek a').filter(function() {
      var el = $(this);
      return el.attr('title') === text;
    });
  }

  function getPriceOfLastItem() {
    var p = $(".cartitems:last .cartitems-itemsum .cartitems-sprice div");
    return textPriceToFloat(p.text());
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
    var subNavLinks = [];
    var isTopLevelLink = true;
    var currentNav = null;
    var errorMsgs = [];

    function preloadSubPages(arr) {
      if(isMobileBrowser) return;

      $.each(arr, function(ind, a) {
        var handler = $(a).attr('onclick');
        var url = handler.replace(/.*(framek[0-9.]+\.htm).*/, '$1');
        // it’s enough to extract the filename since pizza.de rewrites
        // the base href to what we need already.
        $.get(url);
      });
    }

    preloadSubPages(navLinks);

    function getPossibleSubLinks() {
      // TODO: does navigation-3-v8 exist?
      // the currently active page has already been parsed when the main
      // category page was loaded/clicked
      subNavLinks = $.makeArray($("#navigation-2-v8 a:not(.firstactiv)"));
      log("replay: “" + getActiveSubPageText() + "”: found " + subNavLinks.length + " subcategories");
      preloadSubPages(subNavLinks);
    }

    // loads the next sub page in the nav links array.
    function loadNextSubPage() {
      log("replay: loading next page");
      isTopLevelLink = subNavLinks.length === 0;
      currentNav = $((isTopLevelLink ? navLinks : subNavLinks).shift());
      // load sub nav links first
      // if an element has this class, the pizza.de JS code avoids
      // loading it. Therefore remove it to ensure the content_ready
      // event fires.
      currentNav.removeClass('activ');
      currentNav.click();
    }

    // searches current sub page and adds found items to basket. The
    // items get removed from the "to go" list
    function addItemsToBasket() {
      log("replay: searching page “" + getActiveSubPageText() + "” for items");

      items = $.grep(items, function (item, ind) {
        // Deposit is added automatically when selecting the correct products
        if(item["prod"] === "Pfand") return false;

        var link = findLinkWithText(item["prod"]);
        if(link.length === 0) return true; // not found; keep in queue
        if(link.length >= 2) {
          errorMsgs.push("ITEM #"+ind+" AMBIGUOUS: " + item["prod"]);
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
            errorMsgs.push(errmsg + " EXTRA NOT FOUND: " + extra);
          } else if(ingred.length >= 2) {
            errorMsgs.push(errmsg + " EXTRA AMBIGUOUS: " + extra);
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
      var endOfCats = navLinks.length === 0 && subNavLinks.length === 0;
      if(items.length === 0 || (currentNav === null && endOfCats))
        return tearDown();

      if(currentNav === null) {
        loadNextSubPage();
      } else {
        // reset sub page
        currentNav = null;
        addItemsToBasket();
        // check if there are any subpages which also need processing
        // before going to the next category. Only do this on top level
        // links, otherwise this would cause infinite loops.
        if(isTopLevelLink) getPossibleSubLinks();

        // continue with next step
        process();
      }
    }

    function missingItemsToErrors() {
      if(items.length > 0) {
        var list = $.map(items, function(item) {
          var m = item['prod'];
          if(item['extra'].length > 0) m += ' + ' + item["extra"].join(" + ");
          return m;
        }).join('\n  – ')
        errorMsgs.push('Missing Items:\n  – ' + list);
      }
    }

    function checkFinalSum() {
      var should = parseFloat(window.hipsterReplayFinalSum);
      var have = textPriceToFloat($('.total').text());
      if(should !== have) {
        errorMsgs.push('Final sum does not match. Should be ' + should + '€, but have ' + have + '€. Check for missing products.');
      }
    }

    function tearDown() {
      log('replay: tear down');
      missingItemsToErrors();
      checkFinalSum();
      $('#inhalt').unbind('content_ready', process);
      $("body").removeClass("wait");
      $("#hipsterProgress").hide();
      $.fx.off = false;

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

  function runAfterLoads() {
    for(var i = 0; i < _runAfterLoad.length; i++) {
      _runAfterLoad[i]();
    }
    _runAfterLoad = null;
  }

  function setupMutationObserver() {
    var MutationObserver = window.MutationObserver || window.WebKitMutationObserver;
    var waitForLoad = new MutationObserver(function(mutations, observer) {
      if(isLoading()) return;
      observer.disconnect();
      runAfterLoads();
    });
    waitForLoad.observe(window.document, { childList: true, subtree: true });
  }

  function setupLegacyObserver() {
    var check = function() {
      if(isLoading()) return;
      $("body").unbind("DOMSubtreeModified", check);
      runAfterLoads();
    }

    $("body").bind("DOMSubtreeModified", check);
  }

  function restorePrefilledAddress(elm) {
    elm = $(elm);
    var field = elm.attr('name').replace(/^odr_/, '');
    var v = window.hipsterPrefillAddress[field];
    if(typeof v === 'undefined' || v === null) {
      return;
    }

    elm.val(v);
  }

  function restoreLocalStorage(elm) {
    elm = $(elm);
    var v = localStorage['hipsterpizza_' + elm.attr('name')];
    if(typeof v === 'undefined' || v === null || v === '') {
      return;
    }

    if(elm.attr('type') === 'radio') {
      $('input[name="'+elm.attr('name')+'"][value="'+v+'"]').click();
    } else {
      elm.val(v);
    }
  }

  function setLocalStorage(elm) {
    elm = $(elm);
    var v = elm.val();

    if(v === '') {
      v = null;
    }
    log('storing: ' + elm.attr('name') + ' = ' + v);
    localStorage['hipsterpizza_' + elm.attr('name')] = v;
  }

  try {
    setupMutationObserver();
  } catch(err) {
    console.log('Using legacy observer (DomSubtreeModified) because MutationObserver seems broken.');
    setupLegacyObserver();
  }

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

    getShopFaxNumber: function() {
      var n = window.cart.config.store.fax;
      n = n.replace(/[^0-9+]/g, '');
      n = n.replace(/^0/, '+49');
      return n;
    },

    detectAndSetShop: function() {
      var button = $('#hipsterShopChooser');
      button.val('Choose ' + hipster.getShopName());

      var hidden = $('#hipsterShopCanonicalUrl');
      hidden.val($("link[rel=canonical]").attr('href'));

      hidden = $('#hipsterShopName');
      hidden.val(hipster.getShopName());

      hidden = $('#hipsterShopFaxNumber');
      hidden.val(hipster.getShopFaxNumber());

      button.show();
      if(window.hipsterSubmitAfterShopDetect) {
        button.click();
      }
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

        // do not ask for user’s nick if editing an order
        if(hipsterGetCookie('action') === 'edit_order') {
          return true;
        }

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
          log("Replaying with error checking");
          replay(data, function(err) {
            if(err.length === 0) return;
            alert('There have been errors replaying the data: \n– ' + err.join('\n– '));
          });
          break;

        case 'nocheck':
          replay(data);
          break;

        case 'insta':
          // if a nickname is already set, simply re-use it without
          // asking.
          var curNick = hipsterGetCookie('nick');
          if(curNick !== '' && curNick !== null) {
            getUserNick = function() { return curNick; };
          }
          replay(data, function() { getSubmitButton().click(); });
          break;

        default:
          err('Invalid replay mode, no action taken');
      }
    },

    attachAddressFieldListener: function() {
      if(!localStorage) return;
      if(window.hipsterPrefillAddress) return;

      // pizza.de replaces the whole sidebar when adding/removing items.
      // Therefore this broad delegate is needed.
      $('body').on('change', 'form#bestellform input, form#bestellform textarea', function() {
        setLocalStorage(this);
      });
    },

    restoreAddressFields: function() {
      if(!localStorage) return;

      $('form#bestellform input, form#bestellform textarea').each(function(idx, elm) {
        if(window.hipsterPrefillAddress) {
          restorePrefilledAddress(elm);
        } else {
          restoreLocalStorage(elm);
        }
      });
    },

    attachShaAddress: function() {
      $('#hipsterSetSubmitTime').on('submit', function() {
        var addr = getShaAddress();
        if(addr !== null) {
          $('#hipsterShaAddress').val();
        }
      });
    },

    autoFillPostalCode: function() {
      if(window.location.pathname === '/pizzade_root') {
        getPostalCode();
      }
    }
  };
})();


hipster.disableAreaCodePopup();
hipster.autoFillPostalCode();


hipster.runAfterLoad(function() {
  hipster.replayData();
  hipster.detectAndSetShop();
  hipster.hideOrderFieldsAppropriately();
  hipster.bindSubmitButton();
  hipster.restoreAddressFields();
  hipster.attachAddressFieldListener();
  hipster.attachShaAddress();
});
