IS_EDU = new RegExp('\.edu\s*$', 'i')

class OX.Signup.EmailValue

  constructor: ->
    _.bindAll(@, 'onChange', 'onSubmit')
    @group = $('.email-input-group.newflow')
    @email = @group.find('.signup_email').show()
    @group.find(".edu.warning").hide();
    @email.change(@onChange)
    @group.closest('form').submit(@onSubmit)
    @userType = ''
    Mailcheck.defaultTopLevelDomains.concat(['pl']) # extend TLDs for our Polish users

  onChange: ->
    if @showing_warning
      @clearWarnings()


  onSubmit: (ev) ->
    if not ((@email.val() == '') or @showing_warning or IS_EDU.test(@email.val()))
      if @userType is 'instructor'
        @showing_warning = true
        @group.addClass('has-error')
        @group.find(".errors").empty()
        @group.find(".edu.warning").show()
        @email.focus()
        ev.preventDefault()
      else
        $("#signup_email").mailcheck(
          suggested: (element, suggestion) =>
            @showing_warning = true
            @group.addClass('has-error')
            @group.find(".errors").empty()
            @group.find("#suggestion").text(suggestion.domain)
            @group.find(".mistype.warning").show()
            $('#signup_email').focus()
            ev.preventDefault()

          empty: (element) ->
            $(".mistype.warning").hide()
        )

  clearWarnings: () ->
    @group.removeClass('has-error')
    @group.find(".edu.warning").hide()
    @group.find(".mistype.warning").hide()
    @showing_warning = false
    Accounts.Ui.checkCheckedButton('#signup_form_submit_button', '#signup_terms_accepted')

  setType: (newUserType) ->
    newUserType = if newUserType == "student" then "student" else "instructor"
    @group.find("[data-audience=\"#{@userType}\"]").hide()
    @userType = newUserType
    @group.find("[data-audience=\"#{@userType}\"]").show()

