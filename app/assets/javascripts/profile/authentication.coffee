BASE_URL = "#{OX.url_prefix}"

# omniauth 2.0 only accepts the OAuth request phase over POST (CVE-2015-9284). This mirrors what
# jquery_ujs does for `link_to method: :post`: build a detached, CSRF-tokened form and submit it
# as a top-level POST navigation to the request phase. The token comes from the page's
# csrf_meta_tags and is validated by omniauth-rails_csrf_protection.
postToRequestPhase = (url) ->
  param = $('meta[name="csrf-param"]').attr('content') or 'authenticity_token'
  token = $('meta[name="csrf-token"]').attr('content')
  $('<form>', method: 'post', action: url)
    .append($('<input>', type: 'hidden', name: param, value: token))
    .hide()
    .appendTo('body')
    .submit()

class AuthenticationOption

  constructor: (@el) ->
    _.bindAll(@, _.functions(@)...)
    this.$el = $(@el)
    this.$el.find('.delete').click(@confirmDelete)
    this.$el.find('.delete--newflow').click(@confirmDeleteNewflow)
    this.$el.find('.add').click(@add)
    this.$el.find('.add--newflow').click(@addNewflow)

  confirmDelete: (ev) ->
    new OX.ConfirmationPopover(
      title: ''
      message: OX.I18n.authentication.confirm_delete
      target: ev.target
      placement: 'top'
      onConfirm: @delete
    )

  confirmDeleteNewflow: (ev) ->
    new OX.ConfirmationPopover(
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
    postToRequestPhase("#{BASE_URL}/i/auth/#{@getType()}")

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

}
