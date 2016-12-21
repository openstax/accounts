class OX.FacultyAccess.RoleSelector

  @initialize: ->
    role = $('#apply_role')
    @role_selector = new RoleSelector(role) if role.length

  constructor: (@el) ->
    _.bindAll(@, 'onChange')
    @el.change(@onChange)

    if @el.val()
      $('#role-dependent-fields').show() # avoid slideDown if role set on load
      @onChange()


  onChange: ->
    if @el.val() == "instructor"
      $('[data-only="instructor"]').parent().show()
      $('[data-except="instructor"]').parent().hide()
    else
      $('[data-only="instructor"]').parent().hide()
      $('[data-except="instructor"]').parent().show()

    $('#role-dependent-fields').slideDown()
