sendMsg = (msg) ->
  window.parent.OxAccount.proxy.post(msg)

relayWindowSize = ->
  win = $(window)
  doc = $(document)
  sendMsg
    pageResize: {
      width:  Math.max(doc.width(), win.width())
      height: Math.max(doc.height(), win.height())
    }

relayHeading = ->
  heading = $('#page-heading')
  return unless heading.length
  sendMsg(setTitle: heading.text())
  heading.hide()


isIframed = ->
  try # IE can block access to window.top
    return window.self != window.top
  catch
    return true # iframed if accessing window.top threw exception

openSocial = (ev) ->
  #sendMsg(openSocialLogin: @href)
  #ev.preventDefault()
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
  window.parent.OxAccount.trigger('social-login:start')
  ev.preventDefault()


$(document).ready ->
  # Are we being loaded inside a popup window in response to a social login?
  window.opener?.parent?.OxAccount?.Host.socialLoginComplete(window)

  return unless isIframed() # don't do anything if not inside an iframe

  relayHeading()

  # we're loading a page from the "normal" website inside the iframe
  # Set a css class so styles can be adjusted
  $(document.body).addClass('iframe')
  # Intercept login button clicks to open in window
  $('.login-button').on('click', openSocial)

  # notify the parent iframe of our size now and whenever it's changed
  $(window).resize( relayWindowSize )
  relayWindowSize()

  # Let the parent of the iframe know that a page was loaded
  sendMsg(pageLoad: window.location.pathname)
