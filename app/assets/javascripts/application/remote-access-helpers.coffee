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

# The social login buttons (twitter, fb, google)
# cannot be loaded inside of an iframe.
# We break out of the frame and display them in a popup window.
openSocial = (ev) ->

  url = @href
  btn = ev.target

  width  = 350
  height = 250
  left = (screen.width/2)-(width/2)
  top  = (screen.height/2)-(height/2)

  separator = if url.indexOf('?') is -1 then '?' else '&'
  url += (separator + 'display=popup')

  window.open(url, @id, "menubar=no,toolbar=no,status=no,width="+width+
    ",height="+height+",toolbar=no,left="+left+",top="+top)

  window.parent.OxAccount.proxy.post({startSocialLogin: @href})
  ev.preventDefault()

$(document).ready ->

  if isIframed() or (window.opener and window.name is 'oxlogin')
    # we're being loaded inside an iframe or a popup
    # Set a css class to adjusted to fit a narrow screen
    $(document.body).addClass('condensed')

  return unless isIframed()
  # certain elements are hidden on the iframe
  $(document.body).addClass('iframe')

  relayHeading()

  # notify the parent iframe of our size now and whenever it's changed
  $(window).resize( relayWindowSize )
  relayWindowSize()

  # Let the parent of the iframe know that a page was loaded
  sendMsg(pageLoad: window.location.pathname)
