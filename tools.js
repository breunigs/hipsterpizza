// encoding: iso-8859-1
// (same as pizza.de)

document.write('<div id="hipsterStatus">Order, then click "Bestellen" to commit order to Hipster Pizza.<br/> <a href="'+hipsterPizzaHost+'">Cancel and return to overview</a></div>');

function hipsterSetSubmitData() {
  // set other data
  function setInputByLabel(search, value) {
    var id = $("label:contains('"+search+"')").attr("for");
    if(id === null) {
      console.warn("Could not detect label for search='"+search+"' :/");
      return;
    }
    document.getElementById(id).value = value;
  }

  // this intentionally does not pre-select the Herr/Frau checkbox, so
  // the form can't be submitted by accidentally hitting enter
  setInputByLabel("Firma",      "");
  setInputByLabel("Vorname",    "");
  setInputByLabel("Nachname",   "");
  setInputByLabel("Straße",     "");
  setInputByLabel("Nr.",        "");
  setInputByLabel("Vorwahl",    "");
  setInputByLabel("Telefon-Nr", "");
  setInputByLabel("PLZ",        "");
  setInputByLabel("Ort",        "");
  setInputByLabel("Email",      "");
  // Note: Hinterhof and Bemerkung text fields are simply concatenated
  // when pizza.de generates the fax. The character limit of 600
  // characters is applied to the concatenation.
  setInputByLabel("Hinterhof", "");
}

function hipsterGetPriceForLastItem() {
  var p = $(".cartitems:last .cartitems-itemsum .cartitems-sprice div").text();
  p = $.trim(p).replace(/\s.*$/, "").replace(",", ".");
  return parseFloat(p);
}

function hipsterGetPriceForAllItems() {
  var p = $(".total").text();
  p = $.trim(p).replace(/\s.*$/, "").replace(",", ".");
  return parseFloat(p);
}

// store the given nick in a cookie
function hipsterSetNick(nick) {
  var exdate = new Date();
  exdate.setDate(exdate.getDate() + 365);
  var data = escape(nick) + "; expires=" + exdate.toUTCString();
  document.cookie = "hipsterNick=" + data;
}

// retrieve nick stored in cookie. Returns null if there's no cookie.
function hipsterGetNick() {
  var cookies = document.cookie.split(/;\s*/);
  for (var i=0; i<cookies.length; i++) {
    var x = $.trim(cookies[i].substr(0, cookies[i].indexOf("=")));
    if (x === "hipsterNick")return unescape(cookies[i].substr(cookies[i].indexOf("=") + 1));
  }
  return null;
}

// will be called once the order has been replayed. Does a bit of
// cleanup and then calls hipsterOrderFinishedAlert() which must be
// defined separately for each page.
var hipsterOrderFinishedHasRun = false;
function hipsterOrderFinished() {
  if(hipsterOrderFinishedHasRun) return;
  hipsterOrderFinishedHasRun = true;
  $("body").removeClass("wait");
  hipsterOrderFinishedAlert();
  $.fx.off = false;
}

// sets the GUI to "loading" and waits for one second, before first
// trying to replay the order.
function hipsterSetupReplay() {
  // no items defined, silently abort
  if(typeof(hipsterItems) === "undefined" || hipsterItems === null)
    return;

  $.fx.off = true;

  console.log("Waiting 250ms for page to finish loading...");
  $("body").addClass("wait");
  setTimeout("hipsterStartReplay()", 250);
  $('#hipsterStatus').html('Waiting for page to load');
}

// trys to replay the order. If the page is not yet fully loaded waits
// for a second before trying again.
function hipsterStartReplay() {
  // wait until pizza.de page has loaded completely
  var elm = $("label:contains('Vorwahl')");
  if(elm.length === 0) {
    console.log("nope, waiting another 250ms...");
    return setTimeout("hipsterStartReplay()", 250);
  }

  var currentNav = null;
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
    if(hipsterItems.length === 0 || (currentNav === null && navLinks.length === 0))
      return hipsterOrderFinished();

    // load next sub page
    if(currentNav === null) {
      currentNav = $(navLinks.shift());
      // if an element has this class, the pizza.de JS code avoids
      // loading it. Therefore remove it to ensure the content_ready
      // event fires.
      currentNav.removeClass('activ');
      currentNav.click();
      return;
    }

    // reset sub page
    currentNav = null;

    // iterate over items and add them to basket
    hipsterItems = $.grep(hipsterItems, function (item, ind) {
      var link = $("a[title='"+item["prod"]+"']");
      if(link.length === 0) return true; // not found; keep in queue
      if(link.length >= 2) {
        console.warn("ITEM #"+ind+" AMBIGUOUS: " + item["prod"]);
        // keep item, so it may be added manually later
        return true;
      }
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
      $(".shop-dialog a:contains('in den Warenkorb')").click();

      // comparing prices as sanity check
      if(hipsterGetPriceForLastItem() !== item["price"]) {
        console.warn(errmsg + "Prices do not match. Expected: " + item["price"] + "   Actual price: " + hipsterGetPriceForLastItem());
      }

      // remove item from list
      return false;
    });

    $("#hipsterStatus").html("expect browser hangs!<br>Items to go: " + hipsterItems.length + "<br>" + "Categories to go: " + navLinks.length);

    // continue in a bit
    setTimeout(function() { process(); }, 0);
  }

  // find all available categories. They will be removed one by one
  // after a category has been processed.
  var navLinks = $.makeArray($(".navbars a"));

  // listen to the same event as pizza.de for content loading
  $('#inhalt').bind('content_ready', function() {
    console.log('Content loaded, processing...');
    process();
  });

  // start process
  process();
}
