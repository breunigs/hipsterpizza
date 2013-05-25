function hipsterGetNick() {
  var cookies = document.cookie.split(";");
  for (var i=0; i<cookies.length; i++) {
    var x = cookies[i].substr(0, cookies[i].indexOf("=")).replace(/^\s+|\s$/, "");
    if (x === "hipsterNick")return unescape(cookies[i].substr(cookies[i].indexOf("=") + 1));
  }
  return null;
}

if(hipsterGetNick() != null) {
  var a = document.querySelectorAll(".onlyWithCookies");
  for(var i = 0; i < a.length; i++) {
    if(a[i].getAttribute("data-nick") == hipsterGetNick()) {
      var newClass = a[i].getAttribute("class").replace("onlyWithCookies","" );
      a[i].setAttribute("class", newClass);
    }
  }
}
