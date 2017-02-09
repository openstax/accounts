OX.Alert = {
  displayInsideElement: (element) ->
    # Return a function that will display the alert inside the given element
    (options) -> OX.alert.display(_.extend(options, parentEl: element))

  hideAll: ->
    $('.ox-alert').each -> $(this).alert('close')

  display: (options) ->
    parent = $(options.parentEl or '#application-body')
    alert = parent.find('.alert')
    icon = options.icon or 'exclamation-sign'
    type = options.type or 'danger'
    unless alert.length
      parent.prepend("""
        <div class="ox-alert fade in alert alert-#{type} alert-dismissible" role="alert">
          <span class="glyphicon glyphicon-#{icon}" aria-hidden="true"></span>
          <span class="msg"></span>
          <button type="button" class="close" data-dismiss="alert" aria-label="#{OX.I18n.alert.close}">
            &times;
         </button>
        </div>
      """)
      alert = parent.find('.alert')

    alert.show().find(".msg").text(
      if _.isObject(options) then (options.message or options.statusText) else options
    )
    if options.hideAfter or options.type is 'success'
      _.delay ->
        alert.alert('close')
      , (options.hideAfter or 15000) # defaults to 15 seconds
    alert

}
