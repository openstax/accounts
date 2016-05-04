$(document).ready ->
  # OX_BOOTSTRAP_INFO is set by

  OxAccount.parentLocation = window.OX_BOOTSTRAP_INFO?.parentLocation
  OxAccount.proxy = new Porthole.WindowProxy(OxAccount.parentLocation)
  # Register an event handler to receive messages
  OxAccount.proxy.addEventListener( (msg) ->
    OxAccount.Api[name]?(args) for name, args of msg.data
  )

  OxAccount.proxy.post(iFrameReady: true)
