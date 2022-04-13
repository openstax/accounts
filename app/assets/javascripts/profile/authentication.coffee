BASE_URL = "#{OX.url_prefix}"

class AuthenticationOption

  constructor: (@el) ->
    _.bindAll(@, _.functions(@)...)
    this.$el = $(@el)
    this.$el.find('.delete').click(@confirmDelete)
    this.$el.find('.delete--newflow').click(@confirmDeleteNewflow)
    this.$el.find('.add').click(@add)
    this.$el.find('.add--newflow').click(@addNewflow)

  confirmDelete: (ev) ->
    OX.showConfirmationPopover(
      title: ''
      message: OX.I18n.authentication.confirm_delete
      target: ev.target
      placement: 'top'
      onConfirm: @delete
    )

  confirmDeleteNewflow: (ev) ->
    OX.showConfirmationPopover(
      title: ''
      message: OX.I18n.authentication.confirm_delete
      target: ev.target
      placement: 'top'
      onConfirm: @deleteNewflow
    )

  getType: ->
    this.$el.data('provider')

  delete: ->
    $.ajax({type: "DELETE", url: "#{BASE_URL}/auth/#{@getType()}"})
      .success( @handleDelete )
      .error(OX.Alert.display)

  deleteNewflow: ->
    $.ajax({type: "DELETE", url: "#{BASE_URL}/i/auth/#{@getType()}"})
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

  add: ->
    # TODO: figure out a way for the BE to pass the url
    window.location.href = "#{BASE_URL}/add/#{@getType()}"

  addNewflow: ->
    window.location.href = "#{BASE_URL}/i/auth/#{@getType()}"

  handleDelete: (response) ->
    if response.location?
      window.location.href = response.location
    else
      @moveToDisabledSection()

class Password extends AuthenticationOption

  constructor: (@el) ->
    super
    this.$el.find('.edit').click(@editPassword)
    this.$el.find('.edit--newflow').click(@editPasswordNewflow)
    this.$el.find('.add--newflow').click(@addPasswordNewflow)

  # TODO we should just use normal links for edit and add, instead of these JS handlers

  editPassword: ->
    window.location.href = "#{BASE_URL}/password/reset"

  editPasswordNewflow: ->
    window.location.href = "#{BASE_URL}/i/change_password_form"

  add: ->
    window.location.href = "#{BASE_URL}/password/add"

  addPasswordNewflow: ->
    window.location.href = "#{BASE_URL}/i/change_password_form"

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
