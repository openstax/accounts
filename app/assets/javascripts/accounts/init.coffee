OxAccount.init = ->
  OxAccount.$('script').each  ->
    matchesSelf = @src.match(/(.*)\/assets\/ox-account.js/)
    if matchesSelf
      window.OxAccount.HOST = matchesSelf[ matchesSelf.length-1 ]

  unless OxAccount.HOST and console.warn
    console.warn("Unable to find loading script tag, cannot detect host")

  # Are we being loaded inside a popup window in response to a social login?
  if window.opener?.OxAccount
    window.opener.OxAccount.Host._externalWindowCompleted(window)

  if window is window.top # not iframe
    OxAccount.Remote.init()
  else
    OxAccount.Host.init()

  OxAccount.isReady = true

OxAccount.$(document).ready( OxAccount.init )
