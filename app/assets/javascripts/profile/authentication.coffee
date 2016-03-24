class PasswordInputs

  @defaults = $.extend({}, $.fn.editabletypes.abstractinput.defaults,
    inputclass: ''
    tpl: '''
      <input type="password" name="password" class="form-control input-sm" placeholder="Password">
      <input type="password" name="password_confirmation" class="form-control input-sm" placeholder="Confirm Password">
    '''
  )

  constructor: (options) ->
    this.init('oxpassword', options, PasswordInputs.defaults)

$.fn.editabletypes.oxpassword = PasswordInputs
$.fn.editableutils.inherit(PasswordInputs, $.fn.editabletypes.abstractinput)
$.extend(PasswordInputs.prototype, {
  activate: ->
    this.$input.filter('[name="password"]').focus()

  autosubmit: ->
    this.$input.keydown (e) ->
      $(this).closest('form').submit() if e.which is 13

  input2value: ->
    values = {}
    this.$input.each( (i, el) ->
      return unless el.type is 'password'
      el = $(el)
      values[el.attr('name')] = el.val()
    )
    values

})


class Identity

  constructor: (@el) ->
    _.bindAll(@, _.functions(@)...)
    this.$el = $(el)
    this.$el.find('.delete').click(@delete)
    this.$el.find('.add').click(@add)

  getType: ->
    this.$el.data('provider')

  delete: ->
    $.ajax({type: "DELETE", url: "/identity/#{@getType()}"})
      .success( @moveToDisabledSection )
      .error(OX.displayAlert)

  isEnabled: ->
    this.$el.closest('.enabled-providers').length isnt 0

  moveToEabledSection: ->
    @$el.hide('fast', =>
      $('.enabled-providers .providers').append(@$el)
      @$el.show()
    )

  moveToDisabledSection: ->
    @$el.hide('fast', =>
      $('.other-sign-in .providers').append(@$el)
      @$el.show()
    )

  add: ->
    # TODO: figure out a way for the BE to pass the url
    window.location.href = "/auth/#{@getType()}"

class Password extends Identity

  constructor: (@el) ->
    super
    this.$el.find('.edit').click @editPassword

  editPassword: ->
    identity = this.$el.addClass('editing')
    input = identity.find('.name')
    input.text('')
    input.editable(
      type: 'oxpassword'
      url: '/identity'
      params: (params) -> {identity: params.value}
    ).on('hidden', (e, reason) ->
      input.editable('destroy')
      input.attr('style', '') # editable calls hide() which sets 'display:block'
      input.text('Password')
      identity.removeClass('editing')

    ).on('save', (e, params) =>
      if @isEnabled()
        OX.displayAlert(type: 'success', message: params.response, icon: 'thumbs-up', parentEl: input.closest('.row'))
      else
        @moveToEabledSection()
    )
    # no idea why the defer is needed, but it fails (silently!) without it
    _.defer -> input.editable('show')

  # password identity works by setting the password
  add: ->
    @editPassword()


SPECIAL_TYPES =
  identity: Password

OX.Profile.Authentication = {

  initialize: ->
    $('.authentication').each (i, el) ->
      klass = SPECIAL_TYPES[$(el).data('provider')] or Identity
      new klass(el)

    $('#enable-other-sign-in').click (e) ->
      e.preventDefault()
      $(this).hide()
      $('.row.other-sign-in').slideToggle()


}
