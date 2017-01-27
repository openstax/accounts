class TypeSelector

  constructor: (@el) ->
    _.bindAll(@, 'onChange')

class ProfileTypeSelector extends TypeSelector

  constructor: (@el) ->
    super
    @el.change(@onChange)

  onChange: ->
    this.el.closest('form').submit()


class SignupTypeSelector extends TypeSelector

  constructor: (@el) ->
    super
    $("input[type='submit']").attr('disabled', true)
    @el.change(@onChange)
    @onChange() if @el.val()

  onChange: ->
    $("input[type='submit']").attr('disabled', false)
    @getEmail().setType(@el.val())

  getEmail: ->
    @_email ||= new OX.Signup.EmailValue()


TYPES=
  profile: ProfileTypeSelector
  signup:  SignupTypeSelector

OX.Signup.TypeSelector = {

  initialize: ->
    for type, klass of TYPES
      role = $("##{type}_role")
      if role.length
        @type_selector = new klass(role)
        break

}
