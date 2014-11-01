var isMobileBrowser = (/android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini|capybara/i.test(navigator.userAgent.toLowerCase()));

// turn off any FX because they are too slow on mobile the way they are
// implemented (probably better in newer jQuery versions, but those are
// not used by pizza.de)
$.fx.off = isMobileBrowser;
