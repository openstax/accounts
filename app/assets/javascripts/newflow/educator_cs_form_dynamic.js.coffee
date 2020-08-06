class NewflowUi.CsFormCompleteProfile

  constructor: ->
    _.bindAll(@, 'onSchoolNameChange', 'onSchoolEmailChange', 'onRoleChange', 'onOtherChange', 'onSubmit')
    @form = $('.signup-page.cs-form-complete-profile')

    # fields locators
    @school_name = @findOrLogNotFound(@form, '.school-name')
    @school_email = @findOrLogNotFound(@form, '.school-issued-email')
    @completed_role = @findOrLogNotFound(@form, '.completed-role')
    @other_specify = @findOrLogNotFound(@form, '.other-specify')

    # input fields locators
    @school_name_input = @findOrLogNotFound(@school_name, 'input')
    @school_email_input = @findOrLogNotFound(@school_email, 'input')
    @completed_role_radio = @findOrLogNotFound(@completed_role, "input")
    @other_input = @findOrLogNotFound(@other_specify, "input")

    # error messages locators
    @please_fill_out_school = @findOrLogNotFound(@form, '.school-name.cs-form-mustdo-alert')
    @please_fill_out_school_email = @findOrLogNotFound(@form, '.school-issued-email.cs-form-mustdo-alert')
    @please_fill_out_other = @findOrLogNotFound(@form, '.other.cs-form-mustdo-alert')
    @please_select_role = @findOrLogNotFound(@form, '.completed-role .role.cs-form-mustdo-alert')

    # event listeners
    @school_name_input.on('input', @onSchoolNameChange)
    @school_email_input.on('input', @onSchoolEmailChange)
    @other_input.on('input', @onOtherChange)
    @completed_role_radio.change(@onRoleChange)
    @findOrLogNotFound(@form, 'form').submit(@onSubmit)

    # Continue button
    @continue = @findOrLogNotFound(@form, '#signup_form_submit_button')

    # Hide these fields initially because they only show up depending on the form's state
    @please_fill_out_school.hide()
    @please_fill_out_school_email.hide()
    @please_select_role.hide()
    @please_fill_out_other.hide()
    @other_specify.hide()

  findOrLogNotFound: (parent, selector) ->
    if (found = parent.find(selector))
      return found
    else
      console.log('Couldn\'t find ', selector)
      return null

  onSubmit: (ev) ->
    school_name_valid = @checkSchoolNameValid()
    school_email_valid = @checkSchoolEmailValid()
    role_valid = @checkRoleValid()
    other_valid = @checkOtherValid()

    if not (school_name_valid and
            role_valid and
            school_email_valid and
            other_valid)
      ev.preventDefault()

  checkSchoolNameValid: () ->
    if @school_name_input.val()
      @please_fill_out_school.hide()
      true
    else
      @please_fill_out_school.show()
      false

  checkSchoolEmailValid: () ->
    if @school_email_input.val()
      @please_fill_out_school_email.hide()
      true
    else
      @please_fill_out_school_email.show()
      false

  checkRoleValid: () ->
    if @completed_role_radio.is(":checked")
      @please_select_role.hide()
      true
    else
      @please_select_role.show()
      false

  checkOtherValid: () ->
    return true if @other_input.is(":hidden")

    if @other_input.val()
      @please_fill_out_other.hide()
      true
    else
      @please_fill_out_other.show()
      false

  onSchoolNameChange: ->
    @please_fill_out_school.hide()
    @continue.prop('disabled', false)

  onSchoolEmailChange: ->
    @please_fill_out_school_email.hide()

    if @checkSchoolEmailValid()
      @continue.prop('disabled', false)

  onRoleChange: ->
    @please_select_role.hide()

    # return unless @checkSchoolNameValid()
    # return unless @checkSchoolEmailValid()

    if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_instructor').is(':checked') && @checkSchoolNameValid() )
      @other_specify.hide()
      @please_fill_out_total_num.hide()
      @onSchoolEmailChange()
    else if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_administrator').is(':checked') && @checkSchoolNameValid() )
      @other_specify.hide()
      @onSchoolEmailChange()
    else if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_other').is(':checked') )
      @other_specify.show()
      @please_fill_out_other.hide()

    if @checkSchoolNameValid() && @checkSchoolEmailValid()
      @continue.prop('disabled', false)

  onOtherChange: ->
    @please_fill_out_other.hide()

    if @checkSchoolNameValid() && @checkSchoolEmailValid() && @checkOtherValid()
      @continue.prop('disabled', false)
