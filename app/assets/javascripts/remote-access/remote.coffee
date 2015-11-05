OxAccount.Remote = {

  init: ->
    # social logins conclude here
    window.opener?.parent?.OxAccount.Host.socialLoginComplete(window, OX_BOOTSTRAP_INFO)

  socialLoginComplete: (user) ->
    @setUser(user)
    @displayPage('profile')

  # cross frame communication is established and pages can be loaded
  iFrameReady: (status) ->
    if @nextPage
      @displayPage(@nextPage)
      @nextPage = null

  displayPage: (page) ->
    OxAccount.Modal.setSize(if page is 'profile' then 'lg' else 'md')
    OxAccount.proxy.post(
      if page is 'login'
        {displayLogin: OxAccount.login_path} # set from the bootstrap script
      else
        {loadPage: page}
    )

  # fired when remote page is loaded
  pageLoad: (page) ->
    OxAccount.trigger('page:load', page)

  pageResize: (size) ->
    OxAccount.Modal.setBodySize(size)

  setTitle: (title) ->
    OxAccount.Modal.setTitle(title)

  setUser: (user) ->
    # can't load the login page if user is already logged in
    @nextPage = 'profile' if @nextPage is 'login'
    OxAccount.current_user = user
    OxAccount.trigger('login', user)

}
