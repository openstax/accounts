# The forms in this control are written with x-editable styling so that it looks
# similar to the other controls.

BASE_URL = "/contact_infos"
class Email

  constructor: (@el) ->
    _.bindAll(@, 'saveSearchable', 'confirmDelete', 'delete', 'displayError', 'toggleSpinner')
    this.$el = $(el)
    @id = this.$el.attr('data-id')
    this.$el.find('.delete').click(@confirmDelete)
    this.$el.find('input[type=checkbox]').change(@saveSearchable)
    window.foo = @

  toggleSpinner: (show) ->
    this.$el.find('.spinner').toggle(_.isBoolean(show) and show)

  url: (action) ->
    "#{BASE_URL}/#{@id}" + ( if action then "/#{action}" else '' )

  saveSearchable: (ev) ->
    @toggleSpinner(true)
    data = {is_searchable: ev.target.checked}
    $.ajax({type: "PUT", url: @url('set_searchable'), data})
      .success( (resp) => @set(resp) )
      .error( (resp) =>
        ev.target.checked = not ev.target.checked
        @displayError(resp)
      ).complete(@toggleSpinner)

  set: (contact) ->
    if contact.id?
      @id = contact.id
      this.$el.attr('data-id', contact.id)
    if contact.is_searchable?
      this.$el.find('input[type=checkbox]').prop('checked', contact.is_searchable)


  displayError: (resp) ->
    error = this.$el.find('.alert')
    unless error.length
      error = this.$el.prepend('''
        <div class="alert alert-danger alert-dismissible" role="alert">
           <button type="button" class="close" data-dismiss="alert" aria-label="Close">
             <span aria-hidden="true">&times;</span>
          </button>
          <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
          <span class="msg"></span>
        </div>
      ''')
    error.show().find(".msg").text(resp.statusText)

  confirmDelete: (ev) ->
    [title, message] = if this.$el.siblings('.email-entry').length is 0 # we're the only one
      ["Are you sure?",
      "If you do not have at least one email address on file, we'll be unable to send you account resets"]
    else
      [false, "Are you sure you want to remove this email address from your account?"]
    new OX.ConfirmationPopover(
      title: title
      message: message
      target: ev.target
      placement: 'top'
      onConfirm: @delete
    )

  delete: ->
    @toggleSpinner(true)
    $.ajax(type: "DELETE", url: @url())
      .success( => @$el.remove() )
      .error(@displayError)
      .complete(@toggleSpinner)

OX.Profile.Email = {

  initialize: ->
    $('.email-entry').each ->
      console.log this
      new Email(this)
    @addEmail = $('#add-an-email').click( => @onAddEmail() )

  onAddEmail: ->
    email = $('#email-template').children().clone().addClass('new')
    input = $(email).insertBefore(@addEmail).find('.email')
    @addEmail.hide()

    input.editable(
      url: '/contact_infos'
      mode: 'inline'
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
