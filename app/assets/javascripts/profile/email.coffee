# The forms in this control are written with x-editable styling so that it looks
# similar to the other controls.

BASE_URL = "/contact_infos"
class Email

  constructor: (@el) ->
    _.bindAll(@, 'saveSearchable', 'destroy', 'displayError', 'toggleSpinner')
    this.$el = $(el)
    @id = this.$el.attr('data-id')
    this.$el.find('.delete').click(@destroy)
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
      .error( (resp) =>
        ev.target.checked = !ev.target.checked
        @displayError(resp)
      ).complete(@toggleSpinner)

  displayError: (resp) ->
    error = this.$el.find('.error')
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

  destroy: ->
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
      email.attr('data-id', params.response.contact_info.id)
      email.removeClass('new')
      # editable removes the parent element unless it's inside a defer ?
      _.defer ->
        input.editable('destroy')
        input.text(params.response.contact_info.value)
      new Email(email)
    )
    # no idea why the defer is needed, but it fails (silently!) without it
    _.defer -> input.editable('show')

}
