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

    # The remote code is written to not depend on global jQuery, no reason to pollute
    OxAccount.$ = jQuery.noConflict()

  openSocial: (ev) ->
    btn = ev.target
    url = @href
    width  = 350
    height = 250
    left = (screen.width/2)-(width/2)
    top  = (screen.height/2)-(height/2)

    separator = if url.indexOf('?') is -1 then '?' else '&'
    url += (separator + 'display=popup')

    window.open(url, @id, "menubar=no,toolbar=no,status=no,width="+width+
      ",height="+height+",toolbar=no,left="+left+",top="+top)
    OxAccount.trigger('social-login:start')
    ev.preventDefault()

  initWebsite: ->
    # we're loading a page from the "normal" website inside the iframe
    # Set a css class so styles can be adjusted
    $(document.body).addClass('iframe')
    # Intercept login button clicks to open in window
    for btn in OxAccount.$('.login-button')
      btn.addEventListener('click', @openSocial)

    resize = ->
      win = $(window)
      window.parent.OxAccount.proxy.post(
        pageResize: { width: win.width(), height: win.height() }
      )
    $(window).resize = resize
    resize()
    window.parent.OxAccount.proxy.post(pageLoad: window.location.pathname)

  # callback called when a social login completes
  _externalWindowCompleted: (extWindow) ->
    OxAccount.trigger('social-login:complete')
    extWindow.close()
    # WHAT TO DO NOW?
    window.location.reload()

}
