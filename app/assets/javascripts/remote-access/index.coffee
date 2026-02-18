#= require jquery
#= require ./vendor/porthole
#= require_self
#= require_tree .

window.OxAccount ||= {}

do ->
  # Ensure that all OxAccount.proxy.addEventListener callbacks enforce a strict
  # origin check against the configured parentLocation. This code runs before
  # files loaded via `require_tree .`, so any later registrations will be wrapped.
  secureProxyAddEventListener = ->
    return unless window.OxAccount?.proxy?
    return if window.OxAccount.proxy._originChecked

    originalAddEventListener = window.OxAccount.proxy.addEventListener
    return unless typeof originalAddEventListener is 'function'

    window.OxAccount.proxy.addEventListener = (callback) ->
      # Wrap the provided callback with a strict origin check.
      wrappedCallback = (msg) ->
        parentOrigin = window.OxAccount.parentLocation
        msgOrigin = msg?.origin

        if parentOrigin? and msgOrigin? and msgOrigin is parentOrigin
          callback(msg)
        else if window.console? and console.warn?
          console.warn "OxAccount: blocked postMessage from untrusted origin:", msgOrigin

      originalAddEventListener.call window.OxAccount.proxy, wrappedCallback

    window.OxAccount.proxy._originChecked = true

  # If the proxy already exists, secure it immediately.
  if window.OxAccount.proxy?
    secureProxyAddEventListener()
  # Otherwise, watch for the proxy being assigned later and secure it then.
  else if Object.defineProperty?
    Object.defineProperty window.OxAccount, 'proxy',
      configurable: true
      enumerable: true
      set: (value) ->
        Object.defineProperty window.OxAccount, 'proxy',
          configurable: true
          enumerable: true
          writable: true
          value: value
        secureProxyAddEventListener()
