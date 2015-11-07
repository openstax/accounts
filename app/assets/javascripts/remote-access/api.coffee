# The pages listed here may be loaded at their given urls
# This allows the iframe user to only request valid urls
PAGES = {
  profile: '/profile'
}

# Methods defined here are executed in the accounts side of the iframe
# in response to a message sent from a trusted host who's iframing the page
OxAccount.Api = {

  loadPage: (page) ->
    return unless PAGES[page]
    OxAccount.Host.setUrl(PAGES[page])

  displayLogin: (url) ->
    OxAccount.Host.setUrl("/remote/start_login?start=#{url}")

  # onLogin is actually called by our login completion handler,
  # we just forward data onto listening parent
  onLogin: (data) ->
    OxAccount.proxy.post(onLogin: data)
}
