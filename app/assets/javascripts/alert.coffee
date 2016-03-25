OX.displayAlert = (options) ->
  parent = $(options.parentEl or '#application-body')
  alert = parent.find('.alert')
  icon = options.icon or 'exclamation-sign'
  type = options.type or 'danger'
  unless alert.length
    alert = parent.prepend("""
      <div class="ox-alert alert alert-#{type} alert-dismissible" role="alert">
        <span class="glyphicon glyphicon-#{icon}" aria-hidden="true"></span>
        <span class="msg"></span>
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
          &times;
       </button>
      </div>
    """)

  alert.show().find(".msg").text(
    if _.isObject(options) then (options.message or options.statusText) else options
  )

  alert
