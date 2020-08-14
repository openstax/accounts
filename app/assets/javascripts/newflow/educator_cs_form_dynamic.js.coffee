class NewflowUi.CsFormCompleteProfile

  constructor: ->
    _.bindAll(@, 'onSchoolNameChange', 'onSchoolEmailChange', 'onRoleChange', 'onOtherChange', 'onHowUsingChange', 'onHowChosenChange', 'onTotalNumChange', 'onBooksUsedChange', 'onBooksOfInterestChange', 'onSubmit')
    @initBooksUsedMultiSelect()
    @initBooksOfInterestMultiSelect()
    @form = $('.signup-page.cs-form-complete-profile')

    # fields locators
    @school_name = @findOrLogNotFound(@form, '.school-name-visible')
    @school_email = @findOrLogNotFound(@form, '.school-issued-email')

    @completed_role = @findOrLogNotFound(@form, '.completed-role')
    @other_specify = @findOrLogNotFound(@form, '.other-specify')

    @how_chosen = @findOrLogNotFound(@form, '.how-chosen')
    @how_using = @findOrLogNotFound(@form, '.how-using')
    @total_num_students = @findOrLogNotFound(@form, '.total-num-students')

    @books_used = @findOrLogNotFound(@form, '.books-used')
    @books_of_interest = @findOrLogNotFound(@form, '.books-of-interest')

    # input fields locators
    @school_name_input = @findOrLogNotFound(@school_name, 'input')
    @school_email_input = @findOrLogNotFound(@school_email, 'input')

    @completed_role_radio = @findOrLogNotFound(@completed_role, "input")
    @other_input = @findOrLogNotFound(@other_specify, "input")

    @how_chosen_radio = @findOrLogNotFound(@how_chosen, "input")
    @how_using_radio = @findOrLogNotFound(@how_using, "input")
    @total_num_students_input = @findOrLogNotFound(@total_num_students, "input")

    # book selections
    @books_used_select = @findOrLogNotFound(@books_used, "select")
    @books_of_interest_select = @findOrLogNotFound(@books_of_interest, "select")

    # error messages locators
    @please_fill_out_school = @findOrLogNotFound(@form, '.school-name.cs-form-mustdo-alert')
    @please_fill_out_school_email = @findOrLogNotFound(@form, '.school-issued-email.cs-form-mustdo-alert')

    @please_select_role = @findOrLogNotFound(@form, '.completed-role .role.cs-form-mustdo-alert')
    @please_fill_out_other = @findOrLogNotFound(@form, '.other.cs-form-mustdo-alert')

    @please_select_chosen = @findOrLogNotFound(@form, '.how-chosen .chosen.newflow-mustdo-alert')
    @please_select_using = @findOrLogNotFound(@form, '.how-using .using.newflow-mustdo-alert')
    @please_fill_out_total_num = @findOrLogNotFound(@form, '.total-num-students .total-num.newflow-mustdo-alert')

    @please_select_books_used = @findOrLogNotFound(@form, '.used.newflow-mustdo-alert')
    @please_select_books_of_interest = @findOrLogNotFound(@form, '.books-of-interest.newflow-mustdo-alert')

    # event listeners
    @school_name_input.on('input', @onSchoolNameChange)
    @school_email_input.on('input', @onSchoolEmailChange)

    @completed_role_radio.change(@onRoleChange)
    @other_input.on('input', @onOtherChange)

    @how_chosen_radio.change(@onHowChosenChange)
    @how_using_radio.change(@onHowUsingChange)
    @total_num_students_input.change(@onTotalNumChange)

    @books_used_select.change(@onBooksUsedChange)
    @books_of_interest_select.change(@onBooksOfInterestChange)

    @findOrLogNotFound(@form, 'form').submit(@onSubmit)

    # Continue button
    @continue = @findOrLogNotFound(@form, '#signup_form_submit_button')

    # Hide these fields initially because they only show up depending on the form's state
    @other_specify.hide()
    @how_chosen.hide()
    @how_using.hide()
    @total_num_students.hide()
    @books_used.hide()
    @books_of_interest.hide()

    # Hide all validations messages
    @please_fill_out_school.hide()
    @please_fill_out_school_email.hide()
    @please_select_role.hide()

    @please_select_chosen
    @please_select_using
    @please_fill_out_total_num.hide()

    @please_select_books_used.hide()
    @please_select_books_of_interest.hide()


  findOrLogNotFound: (parent, selector) ->
    if (found = parent.find(selector))
      return found
    else
      console.log('Couldn\'t find ', selector)
      return null

  initBooksUsedMultiSelect: ->
    books_used = document.getElementById('signup_books_used')
    osMultiSelect(books_used)

  initBooksOfInterestMultiSelect: ->
    books_of_interest = document.getElementById('signup_books_of_interest')
    osMultiSelect(books_of_interest)

  onSubmit: (ev) ->
    school_name_valid = @checkSchoolNameValid()
    school_email_valid = @checkSchoolEmailValid()

    role_valid = @checkRoleValid()
    other_valid = @checkOtherValid()

    chosen_valid = @checkChosenValid()
    using_how_valid = @checkUsingHowValid()

    total_num_valid = @checkTotalNumValid()
    books_used_valid = @checkBooksUsedValid()
    books_of_interest_valid = @checkBooksOfInterestValid()

    if not (
      school_name_valid and
      school_email_valid and
      role_valid and
      other_valid and
      chosen_valid and
      using_how_valid and
      total_num_valid and
      books_used_valid and
      books_of_interest_valid
    )
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

  checkChosenValid: () ->
    return true if @how_chosen_radio.is(":hidden")

    if @how_chosen_radio.is(":checked")
      @please_select_chosen.hide()
      true
    else
      @please_select_chosen.show()
      false

  checkUsingHowValid: () ->
    return true if @how_using_radio.is(":hidden")

    if @how_using_radio.is(":checked")
      @please_select_using.hide()
      true
    else
      @please_select_using.show()
      false

  checkTotalNumValid: () ->
    return true if @total_num_students_input.is(":hidden")

    if @total_num_students_input.val()
      @please_fill_out_total_num.hide()
      true
    else
      @please_fill_out_total_num.show()
      false

  checkBooksUsedValid: () ->
    return true if @books_used.is(":hidden")

    if @books_used_select.val()
      @please_select_books_used.hide()
      true
    else
      @please_select_books_used.show()
      false

  checkBooksOfInterestValid: () ->
    return true if @books_of_interest.is(":hidden")

    if @books_of_interest_select.val()
      @please_select_books_of_interest.hide()
      true
    else
      @please_select_books_of_interest.show()
      false

  onSchoolNameChange: ->
    @checkSchoolNameValid()

  onSchoolEmailChange: ->
    @please_fill_out_school_email.hide()

    if @checkSchoolEmailValid()
      @continue.prop('disabled', false)

  onRoleChange: ->
    @please_select_role.hide()

    if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_instructor').is(':checked') && @checkSchoolNameValid() )
      @how_using.show()
      @how_chosen.show()
      @total_num_students.show()

      @other_specify.hide()
      @books_used.hide()
      @please_select_using.hide()
      @please_select_chosen.hide()
      @please_fill_out_total_num.hide()

      @onSchoolEmailChange()
    else if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_administrator').is(':checked') && @checkSchoolNameValid() )
      @how_chosen.show()
      @how_using.show()

      @other_specify.hide()
      @books_used.hide()
      @total_num_students.hide()
      @please_select_chosen.hide()
      @please_select_using.hide()

      @onSchoolEmailChange()
    else if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_other').is(':checked') )
      @other_specify.show()

      @please_fill_out_other.hide()
      @how_chosen.hide()
      @how_using.hide()
      @total_num_students.hide()
      @books_used.hide()
      @books_of_interest.hide()

    if @checkSchoolNameValid() && @checkSchoolEmailValid()
      @continue.prop('disabled', false)

  onOtherChange: ->
    @please_fill_out_other.hide()

    if @checkSchoolNameValid() && @checkSchoolEmailValid() && @checkOtherValid()
      @continue.prop('disabled', false)

  onHowUsingChange: ->
    @please_select_using.hide()

    if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_primary').is(':checked') )
      @books_used.show()

      @books_of_interest.hide()
      @please_select_books_used.hide()
      @please_select_books_of_interest.hide()
    else if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_recommending').is(':checked') )
      @books_of_interest.show()

      @books_used.hide()
      @please_select_books_used.hide()
      @please_select_books_of_interest.hide()
    else if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_future').is(':checked') )
      @books_of_interest.show()

      @books_used.hide()
      @please_select_books_used.hide()
      @please_select_books_of_interest.hide()

  onHowChosenChange: ->
    @please_select_chosen.hide()

  onHowUsingChange: ->
    @please_select_using.hide()

    if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_primary').is(':checked') )
      @books_used.show()

      @books_of_interest.hide()
      @please_select_books_used.hide()
      @please_select_books_of_interest.hide()
    else if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_recommending').is(':checked') )
      @books_of_interest.show()

      @books_used.hide()
      @please_select_books_used.hide()
      @please_select_books_of_interest.hide()
    else if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_future').is(':checked') )
      @books_of_interest.show()

      @books_used.hide()
      @please_select_books_used.hide()
      @please_select_books_of_interest.hide()

  onTotalNumChange: ->
    @please_fill_out_total_num.hide()

  onBooksUsedChange: ->
    return false if !@checkTotalNumValid()

    @please_select_books_used.hide()
    @continue.prop('disabled', false)

  onBooksOfInterestChange: ->
    return false if !@checkTotalNumValid()

    @please_select_books_of_interest.hide()
    @continue.prop('disabled', false)
