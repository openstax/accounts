class OX.Signup.TypeSelector

  @initialize: ->
    role = $('#signup_role')
    @type_selector = new TypeSelector(role) if role.length

  constructor: (@el) ->
    _.bindAll(@, 'onChange', 'onSelect')
    @el.mousedown(@onSelect)
    @el.change(@onChange)
    @onChange() if @el.val() isnt 'initial'


  onSelect: (ev) ->
     # remove the "I am a" option; it's an invalid selection
    initial = this.el.find('option[value="initial"]')
    if initial.length
      @el.val('student') if @el.val() is 'initial'
      initial.remove()
      @onChange()

  onChange: ->
    @getEmail().setType(@el.val())

  getEmail: ->
    @_email ||= new OX.Signup.EmailValue()
