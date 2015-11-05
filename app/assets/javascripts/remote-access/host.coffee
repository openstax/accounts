# Methods defined here are executed in the context host side of the iframe
#
# The pages listed here may be loaded at their given urls
PAGES = {
  login: '/login'
  profile: '/profile'
}

setUrl = (url) ->
  frame = OxAccount.$('#content')
  frame.attr(src: url) unless frame.attr('src') is url


OxAccount.Host = {

  loadPage: (page) ->
    return unless PAGES[page]
    setUrl(PAGES[page])

  displayLogin: (url) ->
    setUrl(url)

  init: ->
    OxAccount.parentLocation = window.OX_BOOTSTRAP_INFO.parentLocation

    OxAccount.proxy = new Porthole.WindowProxy(OxAccount.parentLocation)
    # Register an event handler to receive messages
    OxAccount.proxy.addEventListener( (msg)->
      for name, args of msg.data
        if OxAccount.Host[name]
          OxAccount.Host[name](args)
        else
          obj = {}
          obj[name] = args
          OxAccount.proxy.post(obj)
    )

    if window.OX_BOOTSTRAP_INFO.user
      OxAccount.proxy.post(setUser: window.OX_BOOTSTRAP_INFO.user)

    OxAccount.proxy.post(iFrameReady: true)

  onPageLoad: (page) ->
    OxAccount.proxy.post(pageLoad: page)

  # callback called when a social login completes
  socialLoginComplete: (extWindow, payload) ->
    OxAccount.proxy.post(socialLoginComplete: payload.user)
    extWindow.close()


}
