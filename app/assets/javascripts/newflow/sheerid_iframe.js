// Talks to the SheerID verification iframe: sizes it to its own content, hands
// it the prefill and the focus styles their form doesn't ship.
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
//
// The same postMessage channel carries what we can't otherwise reach: prefill,
// and the keyboard focus ring their stylesheet suppresses -- see
// `sendFocusStyles` below.
(function () {
  'use strict';

  var frame = document.getElementById('sheerid-iframe');
  if (!frame) { return; }

  var uid = frame.getAttribute('data-sheerid-uid');
  var origin = frame.getAttribute('data-sheerid-origin');
  if (!origin) { return; }

  // SheerID's own stylesheet is why this form has no keyboard focus indicator:
  // it ships `outline:none` on `.sid-text-input:focus` and
  // `.sid-h-link-like:focus`, and gives the submit button, the dropzone and the
  // "Add file" button no focus style at all (CORE-909, WCAG 2.4.7 AA).
  //
  // We can't reach into a cross-origin iframe with a stylesheet of our own, and
  // the usual vendor answer -- Theme > Custom CSS in MySheerID -- isn't offered
  // on our program, which exposes a palette and nothing else. But the form
  // accepts a `setOptions` message and renders `options.customCss` into a
  // <style> tag of its own, ahead of any customCss the program theme carries.
  // So the rules travel to the form instead of being applied to it.
  //
  // `!important` earns its place twice over: their `:focus{outline:none}` rules
  // are equally specific, and react-dropzone puts `outline:none` inline on the
  // dropzone, where nothing but `!important` can reach it.
  //
  // 2px #026AA1 offset 2px is what the rest of the signup flow uses, so a
  // keyboard user crossing into the frame sees one indicator rather than two
  // designs. 5.9:1 against the form's white card and 5.3:1 against its grey
  // dropzone, where 2.4.7 asks for 3:1.
  var FOCUS_RING = [
    '  outline: 2px solid #026AA1 !important;',
    '  outline-offset: 2px !important;'
  ];

  var FOCUS_CSS = [
    '.sid-btn:focus-visible,',
    '.sid-btn-light:focus-visible,',
    '.sid-uploadzone__button:focus-visible,',
    '.sid-dropzone-wrap__dropzone:focus-visible,',
    '.sid-text-input:focus-visible,',
    '.sid-h-link-like:focus-visible,',
    '.sid-file-list__remove-btn:focus-visible,',
    '.sid-form-wrapper a:focus-visible,',
    '.sid-form-wrapper button:focus-visible,',
    '.sid-form-wrapper input:focus-visible,',
    '.sid-form-wrapper select:focus-visible,',
    '.sid-form-wrapper textarea:focus-visible,',
    '.sid-form-wrapper [tabindex]:focus-visible {'
  ].concat(FOCUS_RING).concat([
    '}',
    // The checkbox input is visually replaced by a sibling, so the ring has to
    // move with it or it lands on a hidden box.
    '.sid-checkbox__input:focus-visible ~ .sid-checkbox__input-like {'
  ]).concat(FOCUS_RING).concat(['}']).join('\n');

  // Sending this can't ping-pong -- a focus ring changes no layout, so it
  // provokes no `updateHeight` -- but the cap makes that answerable without
  // having to reason it out.
  var MAX_FOCUS_CSS_SENDS = 3;
  var focusCssSends = 0;

  // Options are read when the form next renders, and they stay set, so one
  // delivery before a render is enough. `ON_VERIFICATION_READY` is that moment:
  // the prefill immediately after it updates the form's store, which is the
  // render that picks these rules up. Re-sending on `updateHeight` covers a
  // visitor with no prefill to send, where that render would otherwise wait for
  // the first keystroke.
  function sendFocusStyles() {
    if (focusCssSends >= MAX_FOCUS_CSS_SENDS || !frame.contentWindow) { return; }

    focusCssSends += 1;
    frame.contentWindow.postMessage(
      { action: 'setOptions', options: { customCss: FOCUS_CSS } },
      origin
    );
  }

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
      if (!uid || data.verificationIframeUid === uid) {
        applyHeight(action.height);
        sendFocusStyles();
      }
    } else if (action === 'updateHeight') {
      applyHeight(data.height);
      sendFocusStyles();
    }
  });

  // Where to send the user once SheerID says they are verified. Their program
  // can be configured to redirect instead, but that is a single URL for a
  // program shared by every environment, so it cannot send dev, staging and
  // production to their own step 4. Driving it from the hook keeps it right
  // everywhere and needs no dashboard change.
  function goToNextStep() {
    var path = frame.getAttribute('data-sheerid-success-path');
    if (!path) { return; }

    window.location.assign(path);
  }

  // ON_VERIFICATION_READY is the form telling us it will accept input; prefill
  // before that lands is dropped. `load` alone is too early.
  window.addEventListener('message', function (event) {
    if (event.origin !== origin) { return; }

    var data = event.data;
    if (!data || typeof data !== 'object') { return; }
    if (uid && data.verificationIframeUid !== uid) { return; }

    var action = data.action;
    if (!action || action.type !== 'hook' || !action.hook) { return; }

    if (action.hook.name === 'ON_VERIFICATION_READY') {
      // Before the prefill, not after: the prefill is what re-renders the form,
      // and a render is when it reads the options these rules live in.
      sendFocusStyles();
      sendViewModel();
    } else if (action.hook.name === 'ON_VERIFICATION_SUCCESS') {
      goToNextStep();
    }
  });
})();
