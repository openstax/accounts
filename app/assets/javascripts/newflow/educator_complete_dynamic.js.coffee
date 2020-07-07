class NewflowUi.EducatorComplete

  constructor: ->
    _.bindAll(@, 'onRoleChange', 'onHowUsingChange', 'onHowChosenChange', 'onTotalNumChange', 'onOtherChange', 'onSubmit', 'onSubjectsInterestChange', 'onBooksUsedChange', 'onSchoolNameChange')
    @form = $('.signup-page.completed-step')
    @school_name = @findOrLogNotFound(@form, '.school-name-visible')
    @school_name_input = @findOrLogNotFound(@school_name, 'input')
    @school_name_input.change(@onSchoolNameChange)
    @completed_role = @findOrLogNotFound(@form, '.completed-role')
    @completed_role_radio = @findOrLogNotFound(@completed_role, "input")
    @completed_role_radio.change(@onRoleChange)
    @please_select_role = @findOrLogNotFound(@form, '.completed-role .role.newflow-mustdo-alert')
    @please_select_using = @findOrLogNotFound(@form, '.how-using .using.newflow-mustdo-alert')
    @please_select_chosen = @findOrLogNotFound(@form, '.how-chosen .chosen.newflow-mustdo-alert')
    @please_fill_out_school = @findOrLogNotFound(@form, '.school-name.newflow-mustdo-alert')
    @please_fill_out_other = @findOrLogNotFound(@form, '.other.newflow-mustdo-alert')
    @please_select_subjects_interest = @findOrLogNotFound(@form, '.subjects.newflow-mustdo-alert')
    @please_select_books_used = @findOrLogNotFound(@form, '.used.newflow-mustdo-alert')
    @please_fill_out_total_num = @findOrLogNotFound(@form, '.total-num-students .total-num.newflow-mustdo-alert')
    @findOrLogNotFound(@form, 'form').submit(@onSubmit)
    @how_chosen = @findOrLogNotFound(@form, '.how-chosen')
    @how_chosen_radio = @findOrLogNotFound(@how_chosen, "input")
    @how_chosen_radio.change(@onHowChosenChange)
    @how_using = @findOrLogNotFound(@form, '.how-using')
    @how_using_radio = @findOrLogNotFound(@how_using, "input")
    @how_using_radio.change(@onHowUsingChange)
    @subjects_interest = @findOrLogNotFound(@form, '.subjects-of-interest')
    @subjects_interest_select = @findOrLogNotFound(@subjects_interest, "select")
    @subjects_interest_select.change(@onSubjectsInterestChange)
    @books_used = @findOrLogNotFound(@form, '.books-used')
    @books_used_select = @findOrLogNotFound(@books_used, "select")
    @books_used_select.change(@onBooksUsedChange)
    @total_num_students = @findOrLogNotFound(@form, '.total-num-students')
    @total_num_students_input = @findOrLogNotFound(@total_num_students, "input")
    @total_num_students_input.change(@onTotalNumChange)
    @other_specify = @findOrLogNotFound(@form, '.other-specify')
    @other_input = @findOrLogNotFound(@other_specify, "input")
    @other_input.change(@onOtherChange)
    @continue = @findOrLogNotFound(@form, '#signup_form_submit_button')

    @initMultiSelect()

    @please_fill_out_school.hide()
    @books_used.hide()
    @how_chosen.hide()
    @subjects_interest.hide()
    @total_num_students.hide()
    @how_using.hide()
    @other_specify.hide()
    @please_select_role.hide()
    @please_fill_out_total_num.hide()

  findOrLogNotFound: (parent, selector) ->
    if (found = parent.find(selector))
      return found
    else
      console.log('Couldn\'t find ', selector)
      return null

  onSubmit: (ev) ->
    school_name_valid = @checkSchoolNameValid()
    role_valid = @checkRoleValid()
    chosen_valid = @checkChosenValid()
    using_valid = @checkUsingValid()
    total_num_valid = @checkTotalNumValid()
    other_valid = @checkOtherValid()
    subjects_interest_valid = @checkSubjectsInterestValid()
    books_used_valid = @checkBooksUsedValid()

    if not (role_valid and
            chosen_valid and
            using_valid and
            other_valid and
            school_name_valid and
            total_num_valid and
            subjects_interest_valid and
            books_used_valid)
      ev.preventDefault()

  checkSchoolNameValid: () ->
    return true if document.getElementsByClassName('school-name-visible')[0] == null

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

  checkTotalNumValid: () ->
    return true if @total_num_students_input.is(":hidden")

    if @total_num_students_input.val()
      @please_fill_out_total_num.hide()
      true
    else
      @please_fill_out_total_num.show()
      false

  checkChosenValid: () ->
    return true if @how_chosen_radio.is(":hidden")

    if @how_chosen_radio.is(":checked")
      @please_select_chosen.hide()
      true
    else
      @please_select_chosen.show()
      false

  checkUsingValid: () ->
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

  checkSubjectsInterestValid: () ->
    return true if @subjects_interest.is(":hidden")

    if @subjects_interest_select.val()
      @please_select_subjects_interest.hide()
      true
    else
      @please_select_subjects_interest.show()
      false

  checkBooksUsedValid: () ->
    return true if @books_used.is(":hidden")

    if @books_used_select.val()
      @please_select_books_used.hide()
      true
    else
      @please_select_books_used.show()
      false

  initMultiSelect: ->
    subjects_interest = document.getElementById('signup_subjects_of_interest')
    osMultiSelect(subjects_interest)
    books_used = document.getElementById('signup_books_used')
    osMultiSelect(books_used)

  onRoleChange: ->
    @please_select_role.hide()

    if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_instructor').is(':checked') && @checkSchoolNameValid() )
      @other_specify.hide()
      @books_used.hide()
      @how_using.show()
      @please_select_using.hide()
      @how_chosen.show()
      @please_select_chosen.hide()
      @total_num_students.show()
      @please_fill_out_total_num.hide()
      @onHowUsingChange()
    else if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_admin').is(':checked') && @checkSchoolNameValid() )
      @other_specify.hide()
      @books_used.hide()
      @total_num_students.hide()
      @how_chosen.show()
      @please_select_chosen.hide()
      @how_using.show()
      @please_select_using.hide()
      @onHowUsingChange()
    else if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_other').is(':checked') )
      @other_specify.show()
      @books_used.hide()
      @how_chosen.hide()
      @subjects_interest.hide()
      @total_num_students.hide()
      @how_using.hide()
      @please_fill_out_other.hide()

    if @checkSchoolNameValid()
      @continue.prop('disabled', false)

  onHowUsingChange: ->
    @please_select_using.hide()

    if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_primary').is(':checked') )
      @books_used.show()
      @please_select_books_used.hide()
      @subjects_interest.hide()
    else if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_recommending').is(':checked') )
      @books_used.show()
      @please_select_books_used.hide()
      @subjects_interest.hide()
    else if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_future').is(':checked') )
      @books_used.hide()
      @subjects_interest.show()
      @please_select_subjects_interest.hide()
    @continue.prop('disabled', false)

  onHowChosenChange: ->
    @please_select_chosen.hide()
    @continue.prop('disabled', false)

  onTotalNumChange: ->
    @please_fill_out_total_num.hide()
    @continue.prop('disabled', false)

  onSchoolNameChange: ->
    @please_fill_out_school.hide()
    @continue.prop('disabled', false)

  onOtherChange: ->
    @please_fill_out_other.hide()
    @continue.prop('disabled', false)

  onSubjectsInterestChange: ->
    @please_select_subjects_interest.hide()
    @continue.prop('disabled', false)

  onBooksUsedChange: ->
    @please_select_books_used.hide()
    @continue.prop('disabled', false)
