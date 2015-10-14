OxAccount.Host = {

  loadPage: (page) ->
    frame = document.getElementById('content')
    if page is "profile"
      OxAccount.$(frame).attr(src: "/profile")

  init: ->
    # outer iframe that doesn't change

    if window.location.pathname is "/remote/iframe"
      @initOuter()
    else
      @initWebsite()


  onPageLoad: (page) ->
    OxAccount.proxy.post(pageLoad: page)

  initOuter: ->
    return unless OxAccount.parentLocation
    OxAccount.proxy = new Porthole.WindowProxy(OxAccount.parentLocation)
    # Register an event handler to receive messages
    OxAccount.proxy.addEventListener( (msg)->
      OxAccount.Host[name](args) for name, args of msg.data
    )
    OxAccount.proxy.post(iFrameReady: true)

  onPageLoad: (page) ->
    OxAccount.proxy.post(pageLoad: page)

  initOuter: ->
    # The remote code is written to not depend on global jQuery, no reason to pollute
    OxAccount.$ = jQuery.noConflict()



  # callback called when a social login completes
  _externalWindowCompleted: (extWindow) ->
    OxAccount.trigger('social-login:complete')
    extWindow.close()
    # WHAT TO DO NOW?
    window.location.reload()

}
