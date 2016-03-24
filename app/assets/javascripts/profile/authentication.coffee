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

  delete: ->

class Password extends Identity

  constructor: (@el) ->
    super
    $('.authentication.identity .edit').click @editPassword

  editPassword: ->
    identity = $('.authentication.identity').addClass('editing')
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

    ).on('save', (e, params) ->
      OX.displayAlert(type: 'success', message: params.response, icon: 'thumbs-up', parentEl: input.closest('.row'))
    )
    # no idea why the defer is needed, but it fails (silently!) without it
    _.defer -> input.editable('show')


OX.Profile.Authentication = {

  initialize: ->
    $('.authentication').each (i, el) ->
      el = $(el)
      klass = if el.hasClass('identity') then Password else Identity
      new klass(el)
}
