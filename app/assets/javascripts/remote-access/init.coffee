isIframed = ->
  try # IE can block access to window.top
    return window.self != window.top
  catch
    return true # iframed if accessing window.top threw exception


window.OxAccount.init = ->
  # true if the script is being externally loaded
  # return if OxAccount.isExternallyLoaded
  if isIframed()
    OxAccount.Host.init()
  else
    OxAccount.Remote.init()

  OxAccount.isReady = true

OxAccount.$(document).ready( OxAccount.init )
