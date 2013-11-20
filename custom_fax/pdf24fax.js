var HOST      = 'http://…/'; // include trailing slash!

// when registering an account, ensure the language is set to English.
// Otherwise the script cannot auto-detect if the fax submission has
// been successful.
var PDF24MAIL = '…';
var PDF24PASS = '…';

var TMPPREFIX = '/tmp/hipster_pizza_fax_'




var fs = require('fs');
var tmpdir = TMPPREFIX.replace(/\/[^\/]+$/, '');
if(!fs.isWritable(tmpdir)) {
  console.log('Error: cannot write to ' + tmpdir + ', aborting');
  phantom.exit(1);
}
// clean up so the user doesn’t find any old files when something goes
// awry
if(fs.exists(TMPPREFIX + 'order.pdf')) fs.remove(TMPPREFIX + 'order.pdf');
if(fs.exists(TMPPREFIX + 'final.png')) fs.remove(TMPPREFIX + 'final.png');
if(fs.exists(TMPPREFIX + 'debug.png')) fs.remove(TMPPREFIX + 'debug.png');

var dbgImg = function() {
  casper.echo('==============================================', 'INFO');
  casper.debugHTML();
  casper.echo('==============================================', 'INFO');
  casper.echo('writing ' + TMPPREFIX + 'debug.png');
  casper.capture(TMPPREFIX + 'debug.png');
  casper.echo('FAX TRANSMISSION FAILED', 'ERROR');
  casper.echo('Look above for hints what might be wrong.');
  casper.exit(3);
}

var casper = require('casper').create({
  //~　verbose: true,
  //~　logLevel: 'debug',
  viewportSize: {width: 640, height: 480},
  onTimeout: dbgImg,
  timeout: 20000
});

phantom.cookiesEnabled = true;

var faxNumber = null;

casper.start(HOST + '?action=getfaxnumber', function() {
  this.echo('Getting pizza service fax number');
  faxNumber = this.getPageContent().replace(/^0/, '+49');
  this.echo('\nFAX NUMBER: ' + faxNumber);
  this.echo('HOST:       ' + HOST + '\n');
});

casper.then(function() {
  var sys = require('system');

  this.echo('This will order pizza and YOU will have to pay for it.', 'INFO');
  sys.stdout.write('Continue? [y/N] ');
  var line = sys.stdin.readLine().toLowerCase().trim();

  if(line != 'y') {
    this.echo('Okay, user abort.');
    this.exit(2);
  }
});

casper.then(function() { casper.echo('Blocking further orders'); });
casper.thenOpen(HOST + '?action=marksubmitted', function() {
  this.echo('Downloading order.pdf');
  this.download(HOST + '?action=genpdf', TMPPREFIX + 'order.pdf');
});

casper.then(function() { casper.echo('Loading landing page'); });
casper.thenOpen('https://fax.pdf24.org/', function() {
  this.click('#navBoxRight a');
  this.echo('Loading Login Popup');
});

casper.waitForSelector('#submitBox, #logInSubmitBox');
casper.then(function() {
  this.echo('Logging in');
  this.fill('form[name="loginform"]', {'email': PDF24MAIL, 'password': PDF24PASS }, false);
  this.click('#submitBox input, #logInSubmitBox input');
});

casper.waitForSelector('#mainMenu_settings');


casper.thenOpen('https://faxout.pdf24.org/');
casper.waitForSelector('#submitBtn');
casper.then(function() {
  this.echo('Uploading PDF');
  this.fill('form[name="uploadForm"]', { file: TMPPREFIX + 'order.pdf' }, false);
  this.click('#submitBtn');
});

casper.waitForSelector('#submitButton');
casper.then(function() {
  this.echo('Setting receiver number');
  this.fill('form[name="faxForm"]', { 'numbers[]': faxNumber }, false);
  this.click('#submitButton');

});


casper.waitForSelector('#submitButton');
casper.then(function() {
  this.echo('Clicking through unchangable settings');
  this.click('#submitButton');
});

casper.waitForSelector('#accm');
casper.then(function() {
  this.page.switchToChildFrame(0);
});

casper.waitForSelector('#chooseBtnBox_free');
casper.then(function() {
  this.echo('Choosing free plan for fax submission');
  this.click('#chooseBtnBox_free a');
  this.page.switchToParentFrame();
});

casper.waitForSelector('.layerWindowTableOuter');
casper.then(function() {
  this.echo('================================================', 'INFO');
  var text = this.fetchText('.layerWindowTableOuter').trim();
  this.echo(text);
  this.echo('================================================', 'INFO');
  var fn = TMPPREFIX + 'final.png';
  this.capture(fn);
  this.echo('show last page:   w3m -o ext_image_viewer=false -o confirm_qq=false ' + fn);

  this.echo('\n\n\n');
  if(text.indexOf('Your fax was scheduled') >= 0) {
    this.echo('It appears the fax submission was successful.');
    this.echo('Fax24 should send a mail to your inbox shortly.');
  } else {
    this.echo('FAX TRANSMISSION FAILED', 'ERROR');
    this.echo('Look above for hints what might be wrong.');
    this.exit(4);
  }
});


casper.run(function() {
  this.exit();
});
