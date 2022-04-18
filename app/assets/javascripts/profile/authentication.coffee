BASE_URL = "#{OX.url_prefix}"

class AuthenticationOption

  constructor: (@el) ->
    _.bindAll(@, _.functions(@)...)
    this.$el = $(@el)
    this.$el.find('.delete').click(@confirmDelete)
    this.$el.find('.add').click(@doAdd)

  confirmDelete: (ev) ->
    OX.showConfirmationPopover(
      title: ''
      message: OX.I18n.authentication.confirm_delete
      target: ev.target
      placement: 'top'
      onConfirm: @doDelete
    )

  getType: ->
    this.$el.data('provider')

  doDelete: ->
    $.ajax({type: "DELETE", url: "#{BASE_URL}/auth/#{@getType()}"})
      .success( @handleDelete )
      .error(OX.Alert.display)

  isEnabled: ->
    this.$el.closest('.enabled-providers').length isnt 0

  moveToEnabledSection: ->
    @$el.hide('fast', =>
      $('.enabled-providers .providers').append(@$el)
      @$el.show()
    )

  moveToDisabledSection: ->
    @$el.hide('fast', =>
      $('.other-sign-in .providers').append(@$el)
      @$el.show()
    )

  doAdd: ->
    window.location.href = "#{BASE_URL}/auth/#{@getType()}"

  handleDelete: (response) ->
    if response.location?
      window.location.href = response.location
    else
      @moveToDisabledSection()

class Password extends AuthenticationOption

  constructor: (@el) ->
    super
    this.$el.find('.edit').click(@editPassword)
    this.$el.find('.add').click(@addPassword)

  # TODO we should just use normal links for edit and add, instead of these JS handlers

  editPassword: ->
    window.location.href = "#{BASE_URL}/change_password_form"

  addPassword: ->
    window.location.href = "#{BASE_URL}/change_password_form"

SPECIAL_TYPES =
  identity: Password

OX.Profile.Authentication = {

  initialize: ->
    $('.authentication').each (i, el) ->
      klass = SPECIAL_TYPES[$(el).data('provider')] or AuthenticationOption
      new klass(el)

    $('#enable-other-sign-in').click (e) ->
      e.preventDefault()
      $(this).hide()
      $('.other-sign-in').slideToggle()


}
