// Sizes the SheerID verification iframe to its own content.
//
// SheerID's form posts its height to the parent window, and their install
// library's whole contribution is to listen for that and set style.height.
// We do the same in a dozen lines instead of loading their ES-module bundle
// from a CDN into the origin that handles passwords -- their script would also
// copy every query param on this page into the third-party URL, which is not
// something we want for `r`, `sp` or `client_id`.
//
// Only a program verification URL (services.sheerid.com/verify/<id>/) reports a
// height; a hosted offers.sheerid.com page never does. When nothing arrives the
// iframe keeps the CSS floor, which is why that floor has to stay generous.
(function () {
  'use strict';

  var frame = document.getElementById('sheerid-iframe');
  if (!frame) { return; }

  var uid = frame.getAttribute('data-sheerid-uid');
  var origin = frame.getAttribute('data-sheerid-origin');
  if (!origin) { return; }

  function applyHeight(height) {
    var pixels = parseInt(height, 10);
    if (!pixels || pixels < 0) { return; }

    frame.scrolling = 'no';
    // The floor outranks an inline height, so it has to go once we know the
    // real one -- otherwise every form shorter than the floor keeps the gap.
    frame.style.minHeight = '0';
    frame.style.height = pixels + 'px';
  }

  // A program verification URL ignores prefill query params -- it takes them
  // over postMessage instead, which is what SheerID's own library does. The
  // values ride on data attributes so this file stays free of user data.
  function sendViewModel() {
    var viewModel = {};
    var fields = { firstName: 'first-name', lastName: 'last-name', email: 'email' };
    var any = false;

    for (var key in fields) {
      if (!Object.prototype.hasOwnProperty.call(fields, key)) { continue; }
      var value = frame.getAttribute('data-sheerid-' + fields[key]);
      if (value) { viewModel[key] = value; any = true; }
    }
    if (!any || !frame.contentWindow) { return; }

    frame.contentWindow.postMessage({ action: 'setViewModel', viewModel: viewModel }, origin);
  }

  window.addEventListener('message', function (event) {
    if (event.origin !== origin) { return; }

    var data = event.data;
    if (!data || typeof data !== 'object') { return; }

    // Two shapes come off the same form: a nested one carrying the uid we
    // minted, and a bare {action: 'updateHeight', height: n} with no uid. The
    // second can only be matched on origin, which is why the frame is the only
    // thing on the page allowed to talk to us.
    var action = data.action;

    if (action && action.type === 'updateHeight') {
      if (!uid || data.verificationIframeUid === uid) { applyHeight(action.height); }
    } else if (action === 'updateHeight') {
      applyHeight(data.height);
    }
  });

  // ON_VERIFICATION_READY is the form telling us it will accept input; prefill
  // before that lands is dropped. `load` alone is too early.
  window.addEventListener('message', function (event) {
    if (event.origin !== origin) { return; }

    var data = event.data;
    if (!data || typeof data !== 'object') { return; }
    if (uid && data.verificationIframeUid !== uid) { return; }

    var action = data.action;
    if (action && action.type === 'hook' && action.hook && action.hook.name === 'ON_VERIFICATION_READY') {
      sendViewModel();
    }
  });
})();
