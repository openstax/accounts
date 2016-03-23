class PasswordInputs

  @defaults = $.extend({}, $.fn.editabletypes.abstractinput.defaults,
    inputclass: ''
    tpl: '''
      <input type="password" name="current_password" class="form-control input-sm" placeholder="Current Password">
      <input type="password" name="password" class="form-control input-sm" placeholder="Password">
      <input type="password" name="password_confirmation" class="form-control input-sm" placeholder="Password Confirmation">
    '''
  )

  constructor: (options) ->
    this.init('oxpassword', options, PasswordInputs.defaults)

$.fn.editabletypes.oxpassword = PasswordInputs
$.fn.editableutils.inherit(PasswordInputs, $.fn.editabletypes.abstractinput)
$.extend(PasswordInputs.prototype, {

  activate: ->
    this.$input.filter('[name="current_password"]').focus()

  autosubmit: ->
    this.$input.keydown (e) ->
      $(this).closest('form').submit() if e.which is 13

  input2value: ->
    values = {}
    this.$input.find('input').each( (i, el) ->
      el = $(el)
      values[el.attr('name')] = el.val()
    )
    values

})

OX.Profile.Authentication = {

  initialize: ->
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
      input.text('Simple Password')
      identity.removeClass('editing')
    ).on('save', (e, params) ->
      OX.displayAlert(type: 'success', message: params.response, icon: 'thumbs-up', parentEl: input.closest('.row'))
    )
    # no idea why the defer is needed, but it fails (silently!) without it
    _.defer -> input.editable('show')

}
