// Refreshes the reCAPTCHA v3 token immediately before a signup form submits,
// instead of relying on the token minted once on page load. Google v3 tokens
// expire after 120s and are single-use, so a long-lived signup form (school
// autocomplete, etc.) could submit a stale token; fetching one right at
// submit time keeps it well inside the window.
//
// reCAPTCHA is a risk signal, never a gate: if grecaptcha never loaded, the
// token promise rejects, or it just takes too long, the form submits anyway
// without a fresh token. The server side already allows that case.
//
// This listens in the capture phase (not jQuery's .on, which only attaches
// in the bubble phase) so it runs *before* jQuery-UJS's own delegated submit
// handler, which disables the submit button. That ordering matters: if UJS
// disabled the button on our intercepted (deferred) submit, and the token
// fetch below then failed before we could resubmit, the button would be
// stuck disabled with no way for the user to retry.
(function () {
  var TOKEN_TIMEOUT_MS = 2000;
  var formState = typeof WeakMap === 'function' ? new WeakMap() : null;

  function getState(form) {
    return formState ? formState.get(form) : form.recaptchaSubmitState;
  }

  function setState(form, state) {
    if (formState) {
      formState.set(form, state);
    } else {
      form.recaptchaSubmitState = state;
    }
  }

  document.addEventListener('submit', function (event) {
    var form = event.target;
    if (!(form instanceof HTMLFormElement)) return;

    var widget = form.querySelector('[data-recaptcha-execute-fn]');
    if (!widget) return;

    var state = getState(form);

    // This is the resubmission we triggered ourselves once the token was
    // ready (or we gave up waiting) -- let it proceed untouched.
    if (state === 'ready') {
      setState(form, null);
      return;
    }

    // A token fetch is already in flight for this form; swallow any extra
    // submit attempts (double-click, Enter key, etc.) instead of racing.
    if (state === 'pending') {
      event.preventDefault();
      event.stopImmediatePropagation();
      return;
    }

    var executeFn = window[widget.getAttribute('data-recaptcha-execute-fn')];
    if (typeof executeFn !== 'function') return;

    event.preventDefault();
    event.stopImmediatePropagation();
    setState(form, 'pending');

    var settled = false;
    var timer;

    function finish(token) {
      if (settled) return;
      settled = true;
      clearTimeout(timer);

      if (token) {
        var input = document.getElementById(widget.getAttribute('data-recaptcha-input-id'));
        if (input) input.value = token;
      }

      setState(form, 'ready');
      form.requestSubmit ? form.requestSubmit() : form.submit();
    }

    timer = setTimeout(function () { finish(null); }, TOKEN_TIMEOUT_MS);

    try {
      executeFn().then(finish, function () { finish(null); });
    } catch (error) {
      finish(null);
    }
  }, true);
})();
