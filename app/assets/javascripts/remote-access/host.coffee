# Methods defined here are internal and trusted
# They are not intended to be callable directly by iframe postMessage
OxAccount.Host = {
  onPageLoad: (page) ->
    OxAccount.proxy.post(pageLoad: page)

  loginComplete: (back) ->
    @setUrl(back)

  # we could inspect the url in order to suss out the best action
  # but the sessions controller will also do it for us
  completeRegistration: (url) ->
    @setUrl('/ask_new_or_returning')

  setUrl: (url) ->
    $('#content').attr(src: url)

}
