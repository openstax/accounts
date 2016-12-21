class OX.Signup.TypeSelector

  @initialize: ->
    role = $('#signup_role')
    @type_selector = new TypeSelector(role) if role.length

  constructor: (@el) ->
    _.bindAll(@, 'onChange')
    $("input[type='submit']").attr('disabled', true)
    @el.change(@onChange)
    @onChange() if @el.val()

  onChange: ->
    $("input[type='submit']").attr('disabled', false)
    @getEmail().setType(@el.val())

  getEmail: ->
    @_email ||= new OX.Signup.EmailValue()
