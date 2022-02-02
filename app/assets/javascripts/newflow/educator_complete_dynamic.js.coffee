class NewflowUi.EducatorComplete

  constructor: ->
    _.bindAll(@, 'onSchoolNameChange', 'onRoleChange', 'onOtherChange', 'onHowUsingChange', 'onHowChosenChange', 'onTotalNumChange', 'onBooksUsedChange', 'onBooksOfInterestChange', 'onSubmit')
    @initBooksUsedMultiSelect()
    @initBooksOfInterestMultiSelect()
    @form = $('.signup-page.completed-step')

    # fields locators
    @school_name = @findOrLogNotFound(@form, '.school-name-visible')

    @completed_role = @findOrLogNotFound(@form, '.completed-role')
    @other_specify = @findOrLogNotFound(@form, '.other-specify')

    @how_chosen = @findOrLogNotFound(@form, '.how-chosen')
    @how_using = @findOrLogNotFound(@form, '.how-using')
    @total_num_students = @findOrLogNotFound(@form, '.total-num-students')

    @books_used = @findOrLogNotFound(@form, '.books-used')
    @books_of_interest = @findOrLogNotFound(@form, '.books-of-interest')

    # input fields locators
    @school_name_input = @findOrLogNotFound(@school_name, 'input')

    @completed_role_radio = @findOrLogNotFound(@completed_role, "input")
    @other_input = @findOrLogNotFound(@other_specify, "input")

    @how_chosen_radio = @findOrLogNotFound(@how_chosen, "input")
    @how_using_radio = @findOrLogNotFound(@how_using, "input")
    @total_num_students_input = @findOrLogNotFound(@total_num_students, "input")

    # book selections
    @books_used_select = @findOrLogNotFound(@books_used, "select")
    @books_of_interest_select = @findOrLogNotFound(@books_of_interest, "select")

    # error messages locators
    @please_fill_out_school = @findOrLogNotFound(@form, '.school-name.newflow-mustdo-alert')

    @please_select_role = @findOrLogNotFound(@form, '.completed-role .role.newflow-mustdo-alert')
    @please_fill_out_other = @findOrLogNotFound(@form, '.other.newflow-mustdo-alert')

    @please_select_chosen = @findOrLogNotFound(@form, '.how-chosen .chosen.newflow-mustdo-alert')
    @please_select_using = @findOrLogNotFound(@form, '.how-using .using.newflow-mustdo-alert')
    @please_fill_out_total_num = @findOrLogNotFound(@form, '.total-num-students .total-num.newflow-mustdo-alert')

    @please_select_books_used = @findOrLogNotFound(@form, '.books-used .used.newflow-mustdo-alert')
    @books_used_max = @findOrLogNotFound(@form, '.books-used .used-limit.newflow-mustdo-alert')
    @please_select_books_of_interest = @findOrLogNotFound(@form, '.books-of-interest .books-of-interest.newflow-mustdo-alert')
    @books_of_interest_max = @findOrLogNotFound(@form, '.books-of-interest .books-of-interest-limit.newflow-mustdo-alert')

    # event listeners
    @school_name_input.on('input', @onSchoolNameChange)

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

    # Disable submitting initially
    @continue.prop('disabled', true)

    # Hide these fields initially because they only show up depending on the form's state
    @other_specify.hide()
    @how_chosen.hide()
    @how_using.hide()
    @total_num_students.hide()
    @books_used.hide()
    @books_of_interest.hide()

    # Hide all validations messages
    @please_fill_out_school.hide()
    @please_select_role.hide()
    @please_fill_out_total_num.hide()

    @please_select_books_used.hide()
    @books_used_max.hide()
    @please_select_books_of_interest.hide()
    @books_of_interest_max.hide()

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

    role_valid = @checkRoleValid()
    other_valid = @checkOtherValid()

    chosen_valid = @checkChosenValid()
    using_how_valid = @checkUsingHowValid()

    total_num_valid = @checkTotalNumValid()
    books_used_valid = @checkBooksUsedValid()
    books_used_valid_max = @checkBooksUsedValidMax()
    books_of_interest_valid = @checkBooksOfInterestValid()
    books_of_interest_valid_max = @checkBooksOfInterestValidMax()

    if not (
        school_name_valid and
        role_valid and
        other_valid and
        chosen_valid and
        using_how_valid and
        total_num_valid and
        books_used_valid and
        books_used_valid_max and
        books_of_interest_valid_max and
        books_of_interest_valid)
      ev.preventDefault()

  checkSchoolNameValid: () ->
    return true if document.getElementsByClassName('school-name-visible')[0] == undefined

    if @school_name_input.val()
      @please_fill_out_school.hide()
      true
    else
      @please_fill_out_school.show()
      false

  checkRoleValid: () ->
    if @completed_role_radio.is(":checked")
      @please_select_role.hide()
      true
    else
      @please_select_role.show()
      false

  checkChosenValid: () ->
    return true if @how_chosen_radio.is(":hidden")

    if @how_chosen_radio.is(":checked")
      @please_select_chosen.hide()
      true
    else
      @please_select_chosen.show()
      false

  checkTotalNumValid: () ->
    return true if @total_num_students_input.is(":hidden")

    if @total_num_students_input.val()
      @please_fill_out_total_num.hide()
      true
    else
      @please_fill_out_total_num.show()
      false

  checkUsingHowValid: () ->
    return true if @how_using_radio.is(":hidden")

    if @how_using_radio.is(":checked")
      @please_select_using.hide()
      true
    else
      @please_select_using.show()
      false

  checkOtherValid: () ->
    return true if @other_input.is(":hidden")

    if @other_input.val()
      @please_fill_out_other.hide()
      true
    else
      @please_fill_out_other.show()
      false

  checkBooksUsedValid: () ->
    return true if @books_used.is(":hidden")

    if @books_used_select.val()
      @please_select_books_used.hide()
      true
    else
      @please_select_books_used.show()
      false

  checkBooksUsedValidMax: () ->
    if @books_used_select.val() == null || @books_used_select.val().length < 6
      @books_used_max.hide()
      true
    else
      @books_used_max.show()
      false

  checkBooksOfInterestValid: () ->
    return true if @books_of_interest.is(":hidden")

    if @books_of_interest_select.val()
      @please_select_books_of_interest.hide()
      true
    else
      @please_select_books_of_interest.show()
      false

  checkBooksOfInterestValidMax: () ->
    if @books_of_interest_select.val() == null || @books_of_interest_select.val().length < 6
      @books_of_interest_max.hide()
      true
    else
      @books_of_interest_max.show()
      false

  onSchoolNameChange: ->
    @please_fill_out_school.hide()
    @onRoleChange()

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

      @onHowUsingChange()
    else if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_administrator').is(':checked') && @checkSchoolNameValid() )
      @how_chosen.show()
      @how_using.show()

      @other_specify.hide()
      @books_used.hide()
      @total_num_students.hide()
      @please_select_chosen.hide()
      @please_select_using.hide()

      @onHowUsingChange()
    else if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_other').is(':checked') )
      @other_specify.show()

      @books_used.hide()
      @books_of_interest.hide()
      @how_chosen.hide()
      @total_num_students.hide()
      @how_using.hide()
      @please_fill_out_other.hide()

    if @checkSchoolNameValid()
      @continue.prop('disabled', false)

  onOtherChange: ->
    @please_fill_out_other.hide()

    if @checkSchoolNameValid() && @checkOtherValid()
      @continue.prop('disabled', false)

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
    @checkBooksUsedValidMax()
    return false if !@checkTotalNumValid()

    @please_select_books_used.hide()
    @continue.prop('disabled', false)

  onBooksOfInterestChange: ->
    @checkBooksOfInterestValidMax()
    return false if !@checkTotalNumValid()

    @please_select_books_of_interest.hide()
    @continue.prop('disabled', false)
