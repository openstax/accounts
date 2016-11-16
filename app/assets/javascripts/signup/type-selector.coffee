class OX.Signup.TypeSelector

  @initialize: ->
    role = $('#signup_role')
    @type_selector = new TypeSelector(role) if role.length


  constructor: (@el) ->
    _.bindAll(@, 'onChange', 'onClick')
    @el.click(@onClick)
    @el.change(@onChange)

  onClick: ->
    initial = this.el.find('option[value="initial"]')
    if initial.length
      @el.val('student')
      initial.remove()

  onChange: ->
    @getEmail().setType(@el.val())

  getEmail: ->
    @_email ||= new OX.Signup.EmailValue()
