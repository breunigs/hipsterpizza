//= require jquery_ujs
//= require _both
//= require bootstrap/dropdown
//= require bootstrap/collapse
//= require _static_tools
//= require _guess_postcode


var hipster = window.hipster = (function() {
  'use strict';

  var my = HIPSTER;

  // CACHES ////////////////////////////////////////////////////////////
  var _isShop = null;
  var _isLoading = true;
  var _runAfterLoad = [];

  // PRIVATE ///////////////////////////////////////////////////////////

  function getPostalCode() {
    my.guessPostcode('#plzsearch_input');
  }

  function isShopPage() {
    if(_isShop !== null) {
      return _isShop;
    }

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

    return new jsSHA(addr, 'TEXT').getHash('SHA-512', 'HEX');
  }

  function getCartItemsJson() {
    var data = [];
    $('.cartitems').each(function(ind, elm) {
      var prod = $(elm).find('.cartitems-title div').text();
      var price = $(elm).find('.cartitems-itemsum .cartitems-sprice div').text();
      price = my.textPriceToFloat(price);

      if($.trim(prod) === '' || isNaN(price)) {
        my.err('Couldn’t detect product properly, maybe the script is broken?');
        return;
      }

      var extra = [];
      // subitems = additional toppings, subsubitems = salad dressing in menus
      // do not filter for the <a> element, as items part of a menu won’t be
      // links.
      var finder = '.cartitems-subitem .cartitems-subtitle, .cartitems-subsubitem .cartitems-subtitle';
      $(elm).find(finder).each(function(ind, ingred) {
        extra[ind] = $(ingred).text();
      });

      data[ind] = { 'price': price, 'prod': prod, 'extra': extra.sort() };
    });

    var deposit = my.textPriceToFloat($('.deposit div').text());
    if(!isNaN(deposit) && deposit > 0) {
      data[data.length] = { price: deposit, 'prod': 'Pfand', extra: [] };
    }

    return data;
  }

  function getCartItemsCount() {
    return $('.cartitems').length;
  }

  function getUserNick() {
    var nick = hipsterGetCookie('nick');
    do {
      nick = window.prompt('Your Nick:', nick === null ? '' : nick);
      // user clicked cancel
      if(nick === null) {
        return null;
      }
    } while(nick === '');
    hipsterSetCookie('nick', nick);
    return nick;
  }

  function navLinkIsSelected(navLink) {
    // first is normal pizza.de clients, 2nd variant is Joey’s Pizza
    return navLink.hasClass('activ') || navLink.find('span').hasClass('ausgewaehlt');
  }

  function elementHasText(el, text) {
    var el = $(el);
    return el.text() === text || el.attr('title') === text;
  }

  function findLinkWithText(text) {
    // a row *may* link to the same item more than once. Don’t count these as
    // ambiguous items.
    var matches = $([]);
    $('#framek tr').each(function() {
      var candidates = $(this).find('a').filter(function() {
        return elementHasText(this, text);
      });

      if(candidates.length === 0) {
        return;
      }

      matches.push(candidates.first());
    });

    return matches;
  }

  function getPriceOfLastItem() {
    var p = $('.cartitems:last .cartitems-itemsum .cartitems-sprice div');
    return my.textPriceToFloat(p.text());
  }

  function getActiveSubPageText() {
    return $('.navbars a.activ, .navbars span.ausgewaehlt').text();
  }

  function replay(items, finishCallback) {
    // setup
    my.log('replay: setup started');
    $.fx.off = true;
    $('body').addClass('wait');
    var navLinks = $.makeArray($('.navbars a'));

    var subNavLinks = [];
    var isTopLevelLink = true;
    var currentNav = null;
    var errorMsgs = [];
    var loadingWatchdog = null;

    function preloadSubPages(arr) {
      if(isMobileBrowser) {
        return;
      }

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
      subNavLinks = $.makeArray($('#navigation-2-v8 a:not(.firstactiv)'));
      my.log('replay: “' + getActiveSubPageText() + '”: found ' + subNavLinks.length + ' subcategories');
      preloadSubPages(subNavLinks);
    }

    // loads the next sub page in the nav links array.
    function loadNextSubPage() {
      // load sub nav links first
      isTopLevelLink = subNavLinks.length === 0;
      currentNav = $((isTopLevelLink ? navLinks : subNavLinks).shift());
      my.log('replay: loading next page ' + $.trim(currentNav.text()), currentNav);

      if(navLinkIsSelected(currentNav)) {
        my.log('replay: skipping initially selected page, has been processed already.', currentNav);
        window.setTimeout(loadNextSubPage, 5);
      } else {
        currentNav.click();
      }
    }

    function activateLoadingWatchdog() {
      var limit = 30;
      loadingWatchdog = window.setTimeout(function() {
        my.log(limit + 's have passed and it seems the page hasn’t loaded. Will pretend it has and continue normally.');
        process();
      }, limit*1000);
    }

    function deactivateLoadingWatchdog() {
      window.clearTimeout(loadingWatchdog);
    }

    function orderDetailsNextStepElements() {
      return $('.shop-dialog a:contains("nächster Schritt"), .shop-dialog a:contains("Extras")');
    }

    function orderDetailsHasMoreSteps() {
      return orderDetailsNextStepElements().length > 0;
    }

    function orderDetailsGotoNextStep() {
      var elem = orderDetailsNextStepElements().first();
      elem.click().remove();
    }

    // Closes order details (like extra ingredients or menu items) if present.
    function orderDetailsClose() {
      $('.shop-dialog a:contains("in den Warenkorb"):first').click();
    }

    function orderDetailsRemoveAutoAddedExtras(extras, errmsg) {
      if(extras.length === 0) {
        return;
      }

      // See if they were included by pizza.de magic and assume they are included
      var completeItem = $('.shop-dialog .dlg-head').text();
      extras = $.grep(extras, function(extra) {
        var found = completeItem.indexOf(extra) >= 0;
        if(found) {
          my.log('removing subitem ' + extra + ' because it appears it was auto-added.');
          return false;
        }
        return true;
      });


      $.each(extras, function(ind, extra) {
        errorMsgs.push(errmsg + ' EXTRA NOT FOUND: ' + extra);
      });

      return extras;
    }

    // searches current sub page and adds found items to basket. The
    // items get removed from the "to go" list
    function addItemsToBasket() {
      my.log('replay: searching page “' + getActiveSubPageText() + '” for items');

      items = $.grep(items, function (item, ind) {
        // Deposit is added automatically when selecting the correct products
        if(item.prod === 'Pfand') {
          return false;
        }

        var link = findLinkWithText(item.prod);
        if(link.length === 0) {
          // not found; keep in queue
          return true;
        }
        if(link.length >= 2) {
          errorMsgs.push('ITEM #' + ind + ' AMBIGUOUS: ' + item.prod);
          // keep item, so it may be added manually later
          return true;
        }

        my.log('replay: found item “' + item.prod + '”');

        var errmsg = 'product='+item.prod+'  | ';
        // exactly one link found. Add it to cart or open extra
        // ingredients popup. If an item can't have extra ingredients
        // this will immediately put the item in the cart.
        link.click();
        // add extra ingredients, if any.
        var lookAgain = false;
        do {
          item.extra = $.grep(item.extra, function(extra) {
            // .shop-dialog == the popup
            // .dlg-nodes == the "add items part". Required if
            // an ingredient should be added multiple times. Otherwise
            // the remove item link would be catched as well.
            // .
            var ingred = $('.shop-dialog .dlg-nodes a:contains('+extra+')');

            if(ingred.length === 0) {
              return true; // keep extra item for later
            }

            if(ingred.length >= 2) {
              errorMsgs.push(errmsg + ' EXTRA AMBIGUOUS: ' + extra);
              return false; // remove item from list
            }

            ingred.click();
            return false;
          });

          lookAgain = item.extra.length > 0 && orderDetailsHasMoreSteps();
          if(lookAgain) {
            my.log('replay: missing extra, going to next step. Extras: ' + item.extra.join(', '));
            orderDetailsGotoNextStep();
          }

        } while(lookAgain);

        item.extra = orderDetailsRemoveAutoAddedExtras(item.extra, errmsg);

        orderDetailsClose();

        // comparing prices as sanity check
        if(getPriceOfLastItem() !== item.price) {
          var msg = errmsg + 'Prices do not match. Expected: ' + item.price + '   Actual price: ' + getPriceOfLastItem();
          console.warn(msg);
          errorMsgs.push(msg);
        }

        // remove item from list
        return false;
      });

      my.log('ITEM IN BASKET COUNT: ' + getCartItemsCount());
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
      if(items.length === 0 || (currentNav === null && endOfCats)) {
        return tearDown();
      }

      if(currentNav === null) {
        loadNextSubPage();
        activateLoadingWatchdog();
      } else {
        deactivateLoadingWatchdog();
        // reset sub page
        currentNav = null;
        addItemsToBasket();
        // check if there are any subpages which also need processing
        // before going to the next category. Only do this on top level
        // links, otherwise this would cause infinite loops.
        if(isTopLevelLink) {
          getPossibleSubLinks();
        }

        // continue with next step
        process();
      }
    }

    function missingItemsToErrors() {
      if(items.length > 0) {
        var list = $.map(items, function(item) {
          var m = item.prod;
          if(item.extra.length > 0) {
            m += ' + ' + item.extra.join(' + ');
          }
          return m;
        }).join('\n  – ');
        errorMsgs.push('Missing Items:\n  – ' + list);
      }
    }

    function checkFinalSum() {
      var should = parseFloat(window.hipsterReplayFinalSum);
      var have = my.textPriceToFloat($('.total').text());
      if(should !== have) {
        errorMsgs.push('Final sum does not match. Should be ' + should + '€, but have ' + have + '€. Check for missing products.');
      }
    }

    function tearDown() {
      my.log('replay: tear down');
      missingItemsToErrors();
      checkFinalSum();
      $('#inhalt').unbind('content_ready', process);
      deactivateLoadingWatchdog();

      // avoid content changes on insta mode because the form is submitted
      // immediately anyway.
      if(window.hipsterReplayMode !== 'insta') {
        $('body').removeClass('wait');
        $('#hipster-progress').hide();
        setSubmitButtonState(true);
        $.fx.off = false;
      } else {
        // allow form submission
        getSubmitButton().enable(true);
      }

      if(typeof finishCallback === 'function') {
        my.log('replay: running callback');
        finishCallback(errorMsgs);
      }
    }

    // listen to the same event as pizza.de for content loading
    $('#inhalt').bind('content_ready', process);

    // start processing
    currentNav = 'currentlyLoadedPage';
    process();
  }

  function getSubmitButton() {
    return $('#hipsterOrderSubmitButton');
  }

  function setSubmitButtonState(enabled) {
    var btn = getSubmitButton();
    if(enabled) {
      if(btn.is(':disabled')) {
        btn.attr('class', 'btn btn-primary navbar-btn').enable(true);
      }
    } else {
      if(btn.is(':enabled')) {
        btn.attr('class', 'btn btn-link navbar-btn').enable(false);
      }
    }
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
      if(isLoading()) {
        return;
      }
      observer.disconnect();
      runAfterLoads();
    });
    waitForLoad.observe(window.document, { childList: true, subtree: true });
  }

  function setupLegacyObserver() {
    var check = function() {
      if(isLoading()) {
        return;
      }
      $('body').unbind('DOMSubtreeModified', check);
      // wait until DOMSubtreeModified event is over to match mutation
      // observer behaviour. If not done so, events might still fire for
      // *this* modification, instead of the next one.
      window.setTimeout(runAfterLoads, 0);
    };

    $('body').bind('DOMSubtreeModified', check);
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
    my.log('storing: ' + elm.attr('name') + ' = ' + v);
    localStorage['hipsterpizza_' + elm.attr('name')] = v;
  }

  try {
    setupMutationObserver();
  } catch(error) {
    my.log('Using legacy observer (DomSubtreeModified) because MutationObserver seems broken.');
    setupLegacyObserver();
  }

  // PUBLIC ////////////////////////////////////////////////////////////
  return {
    hideOrderFieldsAppropriately: function() {
      if(my.getCurrentMode() === 'pizzade_basket_submit') {
        my.log('Not hiding address fields because we want to submit the group basket');
        return;
      }

      $('body').addClass('hideOrderFields');
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

      return $('title').text();
    },

    getShopFaxNumber: function() {
      var n = window.cart.config.store.fax;
      n = n.replace(/[^0-9+]/g, '');
      n = n.replace(/^0/, '+49');
      return n;
    },

    detectAndSetShop: function() {
      var button = $('#hipsterShopChooser');
      button.enable();
      button.attr('class', 'btn btn-primary navbar-btn');

      var hidden = $('#hipsterShopCanonicalUrl');
      hidden.val($('link[rel=canonical]').attr('href'));

      hidden = $('#hipsterShopName');
      hidden.val(hipster.getShopName());

      hidden = $('#hipsterShopFaxNumber');
      hidden.val(hipster.getShopFaxNumber());

      hidden = $('#hipsterShopUrlParams');
      hidden.val(window.location.search);

      button.show();
      if(window.hipsterSubmitAfterShopDetect) {
        button.click();
      }
    },

    // Disables annoying popups for common users like “shop closed, preorder?”.
    // This also disables the PLZ/delivery area selector popup. The popup is
    // required to properly set up pizza.de for submission. If the
    // shop_url_params were set properly, the “popup” only contains a JavaScript
    // snippet which sets the required values automatically. See issue #23
    // starting from this comment:
    // https://github.com/breunigs/hipsterpizza/issues/23#issuecomment-60237891
    disableAnnoyingPopups: function() {
      if(!window.cart) {
        return;
      }

      if(my.getCurrentMode() === 'pizzade_basket_submit') {
        my.log('Not hiding annoying popups because we want to submit the group basket');
        return;
      }

      // URLs without &knddomain=1 switch
      window.cart.check4DeliveryArea = function() {};
      // URLs with that switch
      window.cart.config.behavior.checkDeliveryAreaOnCustDomains = 0;
    },


    bindSubmitButton: function() {
      var form = getSubmitButton().parents('form');
      form.submit(function() {
        var items = getCartItemsJson();
        if(items.length === 0) {
          window.alert('You need to select at least one item.');
          return false;
        }
        $('#hipsterOrderJson').val(JSON.stringify(items));

        // do not ask for user’s nick if editing an order
        if(hipsterGetCookie('mode') === 'pizzade_order_edit') {
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
          my.log('Replaying with error checking');
          replay(data, function(err) {
            if(err.length === 0) {
              return;
            }
            window.alert('There have been errors replaying the data: \n– ' + err.join('\n– '));
          });
          break;

        case 'nocheck':
          replay(data);
          break;

        case 'insta':
          // if a nickname is already set, simply re-use it without asking.
          var curNick = hipsterGetCookie('nick');
          if(curNick !== '' && curNick !== null) {
            getUserNick = function() { return curNick; };
          }
          replay(data, function() { getSubmitButton().click(); });
          break;

        default:
          my.err('Invalid replay mode, no action taken');
      }
    },

    attachAddressFieldListener: function() {
      if(!localStorage || window.hipsterPrefillAddress) {
        return;
      }

      // pizza.de replaces the whole sidebar when adding/removing items.
      // Therefore this broad delegate is needed.
      $('body').on('change', 'form#bestellform input, form#bestellform textarea', function() {
        setLocalStorage(this);
      });
    },

    runItemCountChecker: function() {
      if(!isShopPage() || window.hipsterReplayMode === 'insta') {
        return;
      }

      var ca = my.getCurrentMode();
      if(ca !== 'pizzade_order_new' && ca !== 'pizzade_order_edit') {
        return;
      }

      window.setInterval(function() {
        setSubmitButtonState(getCartItemsCount() !== 0);
      }, 1000);
    },

    restoreAddressFields: function() {
      if(!localStorage) {
        return;
      }

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

hipster.disableAnnoyingPopups();
hipster.autoFillPostalCode();


hipster.runAfterLoad(function() {
  'use strict';

  hipster.bindSubmitButton();
  hipster.replayData();
  hipster.detectAndSetShop();
  hipster.hideOrderFieldsAppropriately();
  hipster.restoreAddressFields();
  hipster.attachAddressFieldListener();
  hipster.attachShaAddress();
  hipster.runItemCountChecker();
});
