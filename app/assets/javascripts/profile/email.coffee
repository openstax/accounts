# The forms in this control are written with x-editable styling so that it looks
# similar to the other controls.

BASE_URL = "#{OX.url_prefix}/contact_infos"

class Email

  constructor: (@el) ->
    _.bindAll(@, _.functions(@)...)
    this.$el = $(@el)
    @id = this.$el.attr('data-id')
    this.$toggle = this.$el.find('.email-entry__toggle')
    this.$controls = this.$el.find('.email-entry__controls')
    this.$toggle.on('click', @toggleControls)
    this.$el.find('.searchable').change(@saveSearchable)
    this.$el.find('.resend-confirmation').click(@sendVerification)
    @update()

  update: ->
    delBtn = this.$el.find('.delete')
    delBtn.off('click', @confirmDelete)
    if @isOnlyVerifiedEmail()
      delBtn.hide()
    else
      delBtn.on('click', @confirmDelete)

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
      title: ''
      message: OX.I18n.email.confirm_delete
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

  toggleControls: (ev) ->
    ev.preventDefault()
    expanded = not @$el.hasClass('is-open')
    if expanded
      $('.email-entry.is-open').each ->
        $(this).removeClass('is-open')
        $(this).find('.email-entry__controls').attr('aria-hidden', true)
        $(this).find('.email-entry__toggle').attr('aria-expanded', false)
    @$el.toggleClass('is-open', expanded)
    this.$toggle.attr('aria-expanded', expanded)
    this.$controls.attr('aria-hidden', !expanded)

OX.Profile.Email = {

  initialize: ->
    $('.email-entry').each (indx, el) ->
      $(el).data(email: new Email(this))
    @addEmail = $('#add-an-email').click( => @onAddEmail() )

  onDeleteEmail: ->
    $('.info .email-entry').each (indx, el) ->
      $(el).data().email.update()

  onAddEmail: ->
    @addEmail.hide()
    email = $('#email-template').children().clone().addClass('new')
    $('#add-an-email-editable').append(email)
    input = $(email).find('.value')
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
    _.defer ->
      input.editable('show')
      labelText = document.createTextNode('Add new email')
      br = document.createElement('br')
      label = document.querySelector('.email-entry.new label')
      label.prepend(br)
      label.prepend(labelText)

}
