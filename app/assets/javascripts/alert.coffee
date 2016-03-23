OX.displayAlert = (options) ->
  parent = $(options.parentEl or '#application-body')
  alert = parent.find('.alert')
  icon = options.icon or 'exclamation-sign'
  type = options.type or 'danger'
  unless alert.length
    alert = parent.prepend("""
      <div class="alert alert-#{type} alert-dismissible" role="alert">
         <button type="button" class="close" data-dismiss="alert" aria-label="Close">
           <span aria-hidden="true">&times;</span>
        </button>
        <span class="glyphicon glyphicon-#{icon}" aria-hidden="true"></span>
        <span class="msg"></span>
      </div>
    """)

  alert.show().find(".msg").text(
    if _.isObject(options) then (options.message or options.statusText) else options
  )

  alert
