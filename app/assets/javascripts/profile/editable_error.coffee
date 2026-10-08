# x-editable ships no error handling of its own. When a save request fails it
# falls back to `xhr.responseText` and injects that straight into the form's
# error block as markup (see `.fail()` in vendor/assets/javascripts/bootstrap-editable.js).
# Any response that isn't our JSON error body -- a rescued exception rendered in
# the `newflow_error` layout, the login page after a session times out, a proxy's
# own 502 page -- therefore lands under the inputs as a full HTML document, and
# comes back every time the form is reopened.
#
# Every editable on the profile page routes failures through here instead, so the
# only thing that can reach the DOM is one short, escaped sentence.

MAX_MESSAGE_LENGTH = 200

escapeHtml = (text) -> $('<div/>').text(text).html()

# Only a body the server explicitly typed as JSON can be a message meant for a
# person to read. HTML and plain text bodies are error pages, never copy.
jsonBody = (xhr) ->
  return null unless xhr and typeof xhr.getResponseHeader is 'function'
  return null unless /\bjson\b/i.test(xhr.getResponseHeader('Content-Type') or '')
  return xhr.responseJSON if xhr.responseJSON?
  try
    JSON.parse(xhr.responseText)
  catch
    null

# Our endpoints spell validation failures three different ways: a bare string
# ("Email has already been taken"), an array of full messages, or {errors: [...]}.
firstMessage = (body) ->
  candidate = switch
    when typeof body is 'string' then body
    when Array.isArray(body) then body[0]
    when body and typeof body is 'object' then body.errors ? body.error ? body.message
    else null
  candidate = candidate[0] if Array.isArray(candidate)

  return null unless typeof candidate is 'string'
  candidate = candidate.trim()
  return null if candidate.length is 0
  candidate.substring(0, MAX_MESSAGE_LENGTH)

# A failed inline edit is otherwise invisible: this flow captures no save event,
# so there is no way to tell how often a name change silently fails. Record the
# shape of the failure only -- never the submitted values or the response body.
reportFailure = (el, xhr) ->
  return unless window.posthog and typeof window.posthog.capture is 'function'

  $el = $(el)
  window.posthog.capture('profile_inline_edit_failed',
    field: $el.attr('id') or $el.data('name') or 'unknown'
    status: xhr?.status ? 0
  )

# `this` is the editable element: x-editable calls the error callback with
# `options.scope`, which inline mode sets to the element being edited.
OX.Profile.editableError = (xhr) ->
  reportFailure(this, xhr)

  # A 4xx is something the person can act on, so show what the server said.
  # Everything else -- a 5xx, a dropped connection, an HTML body where JSON was
  # promised -- is ours to fix, and Sentry already has it.
  status = xhr?.status ? 0
  body = if 400 <= status < 500 then jsonBody(xhr) else null
  message = if body? then firstMessage(body) else null

  escapeHtml(message or OX.I18n.editable.save_failed)
