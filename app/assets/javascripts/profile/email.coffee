# The forms in this control are written with x-editable styling so that it looks
# similar to the other controls.

BASE_URL = "/contact_infos"
class Email

  constructor: (@el) ->
    _.bindAll(@, _.functions(@)...)
    this.$el = $(@el)
    @id = this.$el.attr('data-id')
    this.$el.find('.searchable').change(@saveSearchable)
    this.$el.find('.verify').click(@sendVerification)
    this.$el.find('.email').click(@toggleProperties)
    @update()

  update: ->
    delBtn = this.$el.find('.delete')
    if @isOnlyVerifiedEmail()
      delBtn.hide()
    else
      delBtn.click(@confirmDelete)

  toggleProperties: ->
    this.$el.toggleClass('expanded')

  toggleSpinner: (show) ->
    this.$el.find('.spinner').toggle(_.isBoolean(show) and show)

  url: (action) ->
    "#{BASE_URL}/#{@id}" + ( if action then "/#{action}" else '' )

  sendVerification: (ev) ->
    ev.preventDefault()
    ev.target.disabled = true
    $.ajax({type: "PUT", url: @url('resend_confirmation')})
      .success( (resp) =>
        OX.Alert.display(message: resp.message, type: 'success', parentEl: @$el)
      )
      .error( (e) =>
        OX.Alert.display(_.extend(e, parentEl: @$el))
        ev.target.disabled = false
      )

  saveSearchable: (ev) ->
    @toggleSpinner(true)
    ev.target.disabled = true
    data = {is_searchable: ev.target.checked}
    $.ajax({type: "PUT", url: @url('set_searchable'), data})
      .success( (resp) => @set(resp) )
      .error( (e) =>
        ev.target.checked = not ev.target.checked
        OX.Alert.display(_.extend(e, parentEl: @$el))
      ).complete( =>
        ev.target.disabled = false
        @toggleSpinner(false)
      )

  set: (contact) ->
    if contact.id?
      @id = contact.id
      this.$el.attr('data-id', contact.id)
    if contact.is_searchable?
      this.$el.find('.searchable').prop('checked', contact.is_searchable)

  isOnlyVerifiedEmail: ->
    @$el.hasClass('verified') and not @$el.siblings('.email-entry.verified').length

  confirmDelete: (ev) ->
    new OX.ConfirmationPopover(
      title: false
      message: "Are you sure you want to remove this email address from your account?"
      target: ev.target
      placement: 'top'
      onConfirm: @delete
    )

  delete: ->
    @toggleSpinner(true)
    $.ajax(type: "DELETE", url: @url())
      .success( =>
        @$el.remove()
        OX.Profile.Email.onDeleteEmail(@)
      )
      .error(OX.Alert.displayInsideElement(@$el))
      .complete(@toggleSpinner)

OX.Profile.Email = {

  initialize: ->
    $('.email-entry').each (indx, el) ->
      $(el).data(email: new Email(this))
    @addEmail = $('#add-an-email').click( => @onAddEmail() )

  onDeleteEmail: ->
    $('.info .email-entry').each (indx, el) ->
      $(el).data().email.update()

  onAddEmail: ->
    email = $('#email-template').children().clone().addClass('new')
    input = $(email).insertBefore(@addEmail).find('.email')
    @addEmail.hide()

    input.editable(
      url: BASE_URL
      params: (params) ->
        'contact_info[type]': 'EmailAddress'
        'contact_info[value]': params.value
      ajaxOptions:
        type: 'POST'
    ).on('hidden', (e, reason) =>
      @addEmail.show()
      email.remove() unless reason is 'save'
    ).on('save', (e, params)->
      email.removeClass('new')
      # editable removes the parent element unless it's inside a defer ?
      _.defer ->
        input.editable('destroy')
        input.text(params.response.contact_info.value)
      email = new Email(email)
      email.set(params.response.contact_info)
    )
    # no idea why the defer is needed, but it fails (silently!) without it
    _.defer -> input.editable('show')

}
