class NewflowUi.EducatorComplete

  constructor: ->
    _.bindAll(@, 'onRoleChange', 'onHowUsingChange', 'onHowChosenChange', 'onTotalNumChange', 'onOtherChange', 'onSubmit', 'onBooksUsedChange', 'onSchoolNameChange')
    @initMultiSelect()
    @form = $('.signup-page.completed-step')

    @other_specify = @findOrLogNotFound(@form, '.other-specify')
    @how_chosen = @findOrLogNotFound(@form, '.how-chosen')
    @how_using = @findOrLogNotFound(@form, '.how-using')
    @total_num_students = @findOrLogNotFound(@form, '.total-num-students')
    @books_used = @findOrLogNotFound(@form, '.books-used')

    @please_select_role = @findOrLogNotFound(@form, '.completed-role .role.newflow-mustdo-alert')
    @please_fill_out_school = @findOrLogNotFound(@form, '.school-name.newflow-mustdo-alert')
    @please_fill_out_total_num = @findOrLogNotFound(@form, '.total-num-students .total-num.newflow-mustdo-alert')
    @please_select_using = @findOrLogNotFound(@form, '.how-using .using.newflow-mustdo-alert')
    @please_select_books_used = @findOrLogNotFound(@form, '.used.newflow-mustdo-alert')

    @other_specify.hide()
    @how_chosen.hide()
    @how_using.hide()
    @total_num_students.hide()
    @books_used.hide()

    @please_select_role.hide()
    @please_fill_out_school.hide()
    @please_fill_out_total_num.hide()

    @school_name = @findOrLogNotFound(@form, '.school-name-visible')
    @school_name_input = @findOrLogNotFound(@school_name, 'input')

    @completed_role = @findOrLogNotFound(@form, '.completed-role')
    @completed_role_radio = @findOrLogNotFound(@completed_role, "input")

    @please_select_chosen = @findOrLogNotFound(@form, '.how-chosen .chosen.newflow-mustdo-alert')
    @how_chosen_radio = @findOrLogNotFound(@how_chosen, "input")

    @how_using_radio = @findOrLogNotFound(@how_using, "input")

    @books_used_select = @findOrLogNotFound(@books_used, "select")
    @books_used_label = @findOrLogNotFound(@form, '.books-used .books_youve_used_label')
    @books_of_interest_label = @findOrLogNotFound(@form, '.books-used .books_of_interest_label')

    @total_num_students_input = @findOrLogNotFound(@total_num_students, "input")

    @please_fill_out_other = @findOrLogNotFound(@form, '.other.newflow-mustdo-alert')
    @other_input = @findOrLogNotFound(@other_specify, "input")

    @school_name_input.on('input', @onSchoolNameChange)
    @completed_role_radio.change(@onRoleChange)
    @other_input.change(@onOtherChange)
    @how_chosen_radio.change(@onHowChosenChange)
    @how_using_radio.change(@onHowUsingChange)
    @total_num_students_input.change(@onTotalNumChange)
    @books_used_select.change(@onBooksUsedChange)

    @findOrLogNotFound(@form, 'form').submit(@onSubmit)
    @continue = @findOrLogNotFound(@form, '#signup_form_submit_button')

  findOrLogNotFound: (parent, selector) ->
    if (found = parent.find(selector))
      return found
    else
      console.log('Couldn\'t find ', selector)
      return null

  initMultiSelect: ->
    books_used = document.getElementById('signup_books_used')
    osMultiSelect(books_used)

  onSubmit: (ev) ->
    school_name_valid = @checkSchoolNameValid()
    role_valid = @checkRoleValid()
    chosen_valid = @checkChosenValid()
    using_valid = @checkUsingValid()
    total_num_valid = @checkTotalNumValid()
    other_valid = @checkOtherValid()
    books_used_valid = @checkBooksUsedValid()

    if not (role_valid and
            chosen_valid and
            using_valid and
            other_valid and
            school_name_valid and
            total_num_valid and
            books_used_valid)
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

  checkBooksUsedValid: () ->
    return true if @books_used.is(":hidden")

    if @books_used_select.val()
      @please_select_books_used.hide()
      true
    else
      @please_select_books_used.show()
      false

  onSchoolNameChange: ->
    @please_fill_out_school.hide()
    @continue.prop('disabled', false)

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
      @total_num_students.hide()
      @how_using.hide()
      @please_fill_out_other.hide()

    if @checkSchoolNameValid()
      @continue.prop('disabled', false)

  onOtherChange: ->
    @please_fill_out_other.hide()
    @continue.prop('disabled', false)

  onHowChosenChange: ->
    @please_select_chosen.hide()
    @continue.prop('disabled', false)

  onHowUsingChange: ->
    @please_select_using.hide()

    if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_primary').is(':checked') )
      @books_used.show()
      @please_select_books_used.hide()
    else if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_recommending').is(':checked') )
      @books_used.show()
      @please_select_books_used.hide()
    else if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_future').is(':checked') )
      @books_used.show()
      @books_used_label.hide()
      @books_of_interest.show()
    @continue.prop('disabled', false)

  onTotalNumChange: ->
    @please_fill_out_total_num.hide()
    @continue.prop('disabled', false)

  onBooksUsedChange: ->
    @please_select_books_used.hide()
    @continue.prop('disabled', false)
