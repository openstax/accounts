IS_EDU = new RegExp('\.edu\s*$', 'i')

class OX.Signup.EmailValue

  constructor: ->
    _.bindAll(@, 'onChange', 'onSubmit')
    @group = $('.email-input-group')
    @email = @group.find('#signup_email').slideDown()
    @email.change(@onChange)
    @group.closest('form').submit(@onSubmit)
    @userType = ''

  onChange: ->
    if @showing_warning
      @group.removeClass('has-error')
      @group.find(".edu-warning").hide()
      @showing_warning = false

  onSubmit: (ev) ->
    if @userType is 'instructor' and not ((@email.val() == '') or @showing_warning or IS_EDU.test(@email.val()))
      @showing_warning = true
      @group.addClass('has-error')
      @group.find(".edu-warning").show()
      @email.focus()
      ev.preventDefault()


  setType: (newUserType) ->
    @group.find("[data-audience=\"#{@userType}\"]").hide()
    @userType = newUserType
    @group.find("[data-audience=\"#{@userType}\"]").show()
