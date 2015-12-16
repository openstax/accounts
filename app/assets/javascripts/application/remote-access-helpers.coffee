## This file is loaded by accounts as part of it's standard JS build
# it watches for page load and applies special handlers if
# it detects it's loaded inside an iframe.

## Sends a messaage back to the listening page using postMessage
sendMsg = (msg) ->
  window.parent.OxAccount.proxy.post(msg)

# Relays the size of the current page so the iframe can resize itself if needed
relayWindowSize = ->
  win = $(window)
  doc = $(document)
  sendMsg
    pageResize: {
      width:  Math.max(doc.width(), win.width())
      height: Math.max(doc.height(), win.height())
    }

# Certain pages have a heading that looks funny when iframed
# We hide it and send it's text to the iframe so it can display it instead
relayHeading = ->
  heading = $('#page-heading')
  return unless heading.length
  sendMsg(setTitle: heading.text())
  heading.hide()

# Check for if running inside iframe
isIframed = ->
  try # IE can block access to window.top
    return window.self != window.top
  catch
    return true # iframed if accessing window.top threw exception


$(document).ready ->

  return unless isIframed()

  # In the future we may also apply the styles to the popup login
  # the below clause will that window
  # or (window.opener and window.name is 'oxlogin')

  # we're being loaded inside an iframe or a popup
  # Set a css class to adjusted to fit a narrow screen
  $(document.body).addClass('condensed iframe')

  relayHeading()

  # notify the parent iframe of our size now and whenever it's changed
  $(window).resize( relayWindowSize )
  relayWindowSize()

  # Let the parent of the iframe know that a page was loaded
  sendMsg(pageLoad: window.location.pathname)
