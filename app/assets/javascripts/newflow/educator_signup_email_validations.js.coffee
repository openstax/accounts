# Institutional email domains: US .edu plus common international academic patterns
# (.edu.au, .ac.uk, .k12.tx.us, .sch.uk, ...). A regex literal keeps the escapes
# that a single-quoted string silently dropped.
IS_EDU = /\.(edu|edu\.[a-z]{2}|ac\.[a-z]{2}|k12\.[a-z]{2}\.us|sch\.[a-z]{2})\s*$/i

class NewflowUi.SignupEmailValidations

  constructor: ->
    _.bindAll(@, 'onChange', 'onSubmit')
    @group = $('.email-input-group.newflow')
    @email = @group.find('.myschool_email').show()
    @email.change(@onChange)
    @group.closest('form').submit(@onSubmit)
    @userType = 'instructor'
    Mailcheck.defaultTopLevelDomains.concat(['pl']) # extend TLDs for our Polish users

  onChange: ->
    if @showing_warning
      @clearWarnings()

  onSubmit: (ev) ->
    if not ((@email.val() == '') or @showing_warning or IS_EDU.test(@email.val()))
      if @userType is 'instructor'
        @showing_warning = true
        window.posthog?.capture('educator_signup_email_suggestion_shown', { form: 'educator_signup' })
        @group.removeClass('has-error')
        @group.find(".errors").empty()
        @group.find(".edu.warning").show()
        @email.focus()
        ev.preventDefault()
        window.setTimeout ( ->
          if ($('#signup_terms_accepted').is(':checked'))
            $('#signup_form_submit_button').prop('disabled', false)
        ), 100
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
    @checkCheckedButton('#signup_form_submit_button', '#signup_terms_accepted')

  checkCheckedButton: (targetSelector, sourceSelector) ->
    if $(sourceSelector).is(':checked')
      @enableButton(targetSelector)
    else
      @disableButton(targetSelector)
