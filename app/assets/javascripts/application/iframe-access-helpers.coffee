relayWindowSize = ->
  win = $(window)
  window.parent.OxAccount.proxy.post(
    pageResize: { width: win.width(), height: win.height() }
  )


$(document).ready ->
  return if window is window.top # don't do anything if not inside an iframe

  # we're loading a page from the "normal" website inside the iframe
  # Set a css class so styles can be adjusted
  $(document.body).addClass('iframe')
  # Intercept login button clicks to open in window
  for btn in $('.login-button')
    btn.addEventListener('click', @openSocial)

  # notify the parent iframe of our size now and whenever it's changed
  $(window).resize( relayWindowSize )
  relayWindowSize()

  # Let the parent of the iframe know that a page was loaded
  window.parent.OxAccount.proxy.post(pageLoad: window.location.pathname)
