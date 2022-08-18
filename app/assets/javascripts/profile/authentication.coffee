BASE_URL = "#{OX.url_prefix}"

class AuthenticationOption

  constructor: (@el) ->
    _.bindAll(@, _.functions(@)...)
    this.$el = $(@el)
    this.$el.find('.delete').click(@confirmDelete)
    if @getType() != 'identity'
      this.$el.find('.add').click(@addSocial)

  confirmDelete: (ev) ->
    OX.showConfirmationPopover(
      title: ''
      message: OX.I18n.authentication.confirm_delete
      target: ev.target
      placement: 'top'
      onConfirm: @delete
    )

  getType: ->
    this.$el.data('provider')

  addSocial: ->
    $.ajax({type: "POST", url: "#{BASE_URL}/auth/#{@getType()}"})
      .success(@handleAdd)
      .error(OX.Alert.display)

  delete: ->
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

  handleAdd: (response) ->
    if response.location?
      window.location.href = response.location
    else
      @moveToEnabledSection()

  handleDelete: (response) ->
    if response.location?
      window.location.href = response.location
    else
      @moveToDisabledSection()

class Password extends AuthenticationOption

  constructor: (@el) ->
    super
    this.$el.find('.add').click(@addPassword)
    this.$el.find('.edit').click(@editPassword)

  # TODO we should just use normal links for edit and add, instead of these JS handlers

  editPassword: ->
    window.location.href = "#{BASE_URL}/password/reset"

  addPassword: ->
    window.location.href = "#{BASE_URL}/password/add"

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
      $('.row.other-sign-in').slideToggle()


}
