(function() {
// This file is loaded by accounts as part of its standard JS build
// it watches for page load and applies special handlers if
// it detects it's loaded inside an iframe.

// Sends a message back to the listening page using postMessage
const sendMsg = msg => window.parent.OxAccount.proxy.post(msg);

// Relays the size of the current page so the iframe can resize itself if needed
const relayWindowSize = function() {
  const win = $(window);
  const doc = $(document);
  return sendMsg({
    pageResize: {
      width:  Math.max(doc.width(), win.width()),
      height: Math.max(doc.height(), win.height())
    }});
};

// Certain pages have a heading that looks funny when iframed
// We hide it and send its text to the iframe so it can display it instead
const relayHeading = function() {
  const heading = $('#page-heading');
  if (!heading.length) { return; }
  sendMsg({setTitle: heading.text()});
  return heading.hide();
};

// Check for if running inside iframe
const isIframed = function() {
  try { // IE can block access to window.top
    return window.self !== window.top;
  } catch (error) {
    return true; // iframed if accessing window.top threw exception
  }
};


$(document).ready(function() {

  if (!isIframed()) { return; }

  // In the future we may also apply the styles to the popup login
  // the below clause will that window
  // or (window.opener and window.name is 'oxlogin')

  relayHeading();

  // notify the parent iframe of our size now and whenever it's changed
  $(window).resize( relayWindowSize );
  relayWindowSize();

  // Let the parent of the iframe know that a page was loaded
  return sendMsg({pageLoad: window.location.pathname});
});
}).call(this);
