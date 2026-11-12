(function() {
// x-editable ships no error handling of its own. When a save request fails it
// falls back to `xhr.responseText` and injects that straight into the form's
// error block as markup (see `.fail()` in vendor/assets/javascripts/bootstrap-editable.js).
// Any response that isn't our JSON error body -- a rescued exception rendered in
// the `newflow_error` layout, the login page after a session times out, a proxy's
// own 502 page -- therefore lands under the inputs as a full HTML document, and
// comes back every time the form is reopened.
//
// Every editable on the profile page routes failures through here instead, so the
// only thing that can reach the DOM is one short, escaped sentence.

const MAX_MESSAGE_LENGTH = 200;

const escapeHtml = text => $('<div/>').text(text).html();

// Only a body the server explicitly typed as JSON can be a message meant for a
// person to read. HTML and plain text bodies are error pages, never copy.
function jsonBody(xhr) {
  if (!xhr || typeof xhr.getResponseHeader !== 'function') { return null; }
  if (!/\bjson\b/i.test(xhr.getResponseHeader('Content-Type') || '')) { return null; }
  if (xhr.responseJSON != null) { return xhr.responseJSON; }
  try {
    return JSON.parse(xhr.responseText);
  } catch (error) {
    return null;
  }
}

// Our endpoints spell validation failures three different ways: a bare string
// ("Email has already been taken"), an array of full messages, or {errors: [...]}.
function firstMessage(body) {
  let candidate;
  if (typeof body === 'string') {
    candidate = body;
  } else if (Array.isArray(body)) {
    candidate = body[0];
  } else if (body && typeof body === 'object') {
    candidate = body.errors != null ? body.errors : (body.error != null ? body.error : body.message);
  } else {
    candidate = null;
  }
  if (Array.isArray(candidate)) { candidate = candidate[0]; }

  if (typeof candidate !== 'string') { return null; }
  candidate = candidate.trim();
  if (candidate.length === 0) { return null; }
  return candidate.substring(0, MAX_MESSAGE_LENGTH);
}

// A failed inline edit is otherwise invisible: this flow captures no save event,
// so there is no way to tell how often a name change silently fails. Record the
// shape of the failure only -- never the submitted values or the response body.
function reportFailure(el, xhr) {
  if (!window.posthog || typeof window.posthog.capture !== 'function') { return; }

  const $el = $(el);
  window.posthog.capture('profile_inline_edit_failed', {
    field: $el.attr('id') || $el.data('name') || 'unknown',
    status: (xhr != null ? xhr.status : undefined) || 0
  });
}

// `this` is the editable element: x-editable calls the error callback with
// `options.scope`, which inline mode sets to the element being edited.
OX.Profile.editableError = function(xhr) {
  reportFailure(this, xhr);

  // A 4xx is something the person can act on, so show what the server said.
  // Everything else -- a 5xx, a dropped connection, an HTML body where JSON was
  // promised -- is ours to fix, and Sentry already has it.
  const status = (xhr != null ? xhr.status : undefined) || 0;
  const body = (status >= 400 && status < 500) ? jsonBody(xhr) : null;
  const message = body != null ? firstMessage(body) : null;

  return escapeHtml(message || OX.I18n.editable.save_failed);
};
}).call(this);
