class AuthenticationOption

  constructor: (@el) ->
    _.bindAll(@, _.functions(@)...)
    this.$el = $(@el)
    this.$el.find('.delete').click(@confirmDelete)
    this.$el.find('.add').click(@add)

  confirmDelete: (ev) ->
    new OX.ConfirmationPopover(
      title: false
      message: "Are you sure you want to remove this sign in option?"
      target: ev.target
      placement: 'top'
      onConfirm: @delete
    )

  getType: ->
    this.$el.data('provider')

  delete: ->
    $.ajax({type: "DELETE", url: "/auth/#{@getType()}"})
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
    window.location.href = "/auth/#{@getType()}"

  handleDelete: (response) ->
    if response.location?
      window.location.href = response.location
    else
      @moveToDisabledSection()

class Password extends AuthenticationOption

  constructor: (@el) ->
    super
    this.$el.find('.edit').click @editPassword

  # TODO we should just use normal links for edit and add, instead of these JS handlers

  editPassword: ->
    window.location.href = "/password/reset"

  add: ->
    window.location.href = "/password/add"

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
