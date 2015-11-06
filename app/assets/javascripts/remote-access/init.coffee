$(document).ready ->
  # OX_BOOTSTRAP_INFO is set by

  OxAccount.parentLocation = window.OX_BOOTSTRAP_INFO.parentLocation
  OxAccount.proxy = new Porthole.WindowProxy(OxAccount.parentLocation)
  # Register an event handler to receive messages
  OxAccount.proxy.addEventListener( (msg)->
    for name, args of msg.data
      if OxAccount.Api[name]
        OxAccount.Api[name](args)
      else
        console.warn?("Method #{name} was called but it's not defined by API")
  )

  if window.OX_BOOTSTRAP_INFO.user
    OxAccount.proxy.post(setUser: window.OX_BOOTSTRAP_INFO.user)

  OxAccount.proxy.post(iFrameReady: true)
