class User

  checkLoginStatus: ->
    OxAccount.$.ajax(url: "#{OxAccount.HOST}/remote/test").then (resp) =>
      @_loginStatus = resp.is_logged_in
      OxAccount.trigger('change:user', @)
    , -> console.error "Check login status FAIL"


  isLoggedIn: -> !!@_loginStatus


OxAccount.User = new User
