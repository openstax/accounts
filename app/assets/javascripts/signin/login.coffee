class OX.Signin.Login

  @initialize: ->
    card = $('.ox-card.login')
    new OX.Signin.Login(card) if card.length

  constructor: (@el) ->
    @el.find('a.trouble').click(@onHelpClick)

  onHelpClick: (ev) =>
    ev.preventDefault()
    @el.find('.login-help').toggle('fast')
