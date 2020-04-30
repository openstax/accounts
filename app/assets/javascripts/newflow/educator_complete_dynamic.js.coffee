class NewflowUi.EducatorComplete

  constructor: ->
    _.bindAll(@, 'onRoleChange', 'onHowUsingChange', 'onHowChosenChange', 'onTotalNumChange', 'onOtherChange', 'onSubmit', 'onSubjectsInterestChange', 'onBooksUsedChange')
    @form = $('.signup-page.completed-step')
    @completed_role = @form.find('.completed-role')
    @completed_role_radio = @completed_role.find("input")
    @completed_role_radio.change(@onRoleChange)
    @please_select_role = @form.find('.completed-role .role.newflow-mustdo-alert')
    @please_select_using = @form.find('.how-using .using.newflow-mustdo-alert')
    @please_select_chosen = @form.find('.how-chosen .chosen.newflow-mustdo-alert')
    @please_fill_out_total_num = @form.find('.total-num.newflow-mustdo-alert')
    @please_fill_out_other = @form.find('.other.newflow-mustdo-alert')
    @please_select_subjects_interest = @form.find('.subjects-of-interest.newflow-mustdo-alert')
    @please_select_books_used = @form.find('.books-used.newflow-mustdo-alert')
    @form.find('form').submit(@onSubmit)
    @how_chosen = @form.find('.how-chosen')
    @how_chosen_radio = @how_chosen.find("input")
    @how_chosen_radio.change(@onHowChosenChange)
    @how_using = @form.find('.how-using')
    @how_using_radio = @how_using.find("input")
    @how_using_radio.change(@onHowUsingChange)
    @subjects_interest = @form.find('.subjects-of-interest')
    @subjects_interest_select = @subjects_interest.find("select")
    @subjects_interest_select.change(@onSubjectsInterestChange)
    @books_used = @form.find('.books-used')
    @books_used_select = @books_used.find("select")
    @books_used_select.change(@onBooksUsedChange)
    @total_num_students = @form.find('.total-num-students')
    @total_num_students_input = @total_num_students.find("input")
    @total_num_students_input.change(@onTotalNumChange)
    @other_specify = @form.find('.other-specify')
    @other_input = @other_specify.find("input")
    @other_input.change(@onOtherChange)
    @continue = @form.find('#signup_form_submit_button')

    @initMultiSelect()

    @books_used.hide()
    @how_chosen.hide()
    @subjects_interest.hide()
    @total_num_students.hide()
    @how_using.hide()
    @other_specify.hide()
    @please_select_role.hide()

  onSubmit: (ev) ->
    role_valid = @checkRoleValid()
    chosen_valid = @checkChosenValid()
    using_valid = @checkUsingValid()
    total_num_valid = @checkTotalNumValid()
    other_valid = @checkOtherValid()
    subjects_interest_valid = @checkSubjectsInterestValid()
    books_used_valid = @checkBooksUsedValid()

    if not (role_valid and chosen_valid and using_valid and other_valid and subjects_interest_valid and books_used_valid)
      ev.preventDefault()

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
    return true if @subjects_interest_select.is(":hidden")

    if @subjects_interest_select.val()
      @please_select_subjects_interest.hide()
      true
    else
      @please_select_subjects_interest.show()
      false

  checkBooksUsedValid: () ->
    return true if @books_used_select.is(":hidden")

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

    if ( $('#signup_completed_role_educator').is(':checked') )
      @other_specify.hide()
      @books_used.hide()
      @how_using.show()
      @please_select_using.hide()
      @how_chosen.show()
      @please_select_chosen.hide()
      @total_num_students.show()
      @please_fill_out_total_num.hide()
    else if ( $('#signup_completed_role_admin').is(':checked') )
      @other_specify.hide()
      @books_used.hide()
      @total_num_students.hide()
      @how_chosen.show()
      @please_select_chosen.hide()
      @how_using.show()
      @please_select_using.hide()
    else if ( $('#signup_completed_role_other').is(':checked') )
      @books_used.hide()
      @how_chosen.hide()
      @subjects_interest.hide()
      @total_num_students.hide()
      @how_using.hide()
      @other_specify.show()
      @please_fill_out_other.hide()
    @continue.prop('disabled', false)

  onHowUsingChange: ->
    @please_select_using.hide()

    if ( $('#signup_using_as_primary').is(':checked') )
      @books_used.show()
      @please_select_books_used.hide()
      @subjects_interest.hide()
    else if ( $('#signup_using_as_recommending').is(':checked') )
      @books_used.show()
      @please_select_books_used.hide()
      @subjects_interest.hide()
    else if ( $('#signup_using_as_future').is(':checked') )
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

  onOtherChange: ->
    @please_fill_out_other.hide()
    @continue.prop('disabled', false)

  onSubjectsInterestChange: ->
    @please_select_subjects_interest.hide()
    @continue.prop('disabled', false)

  onBooksUsedChange: ->
    @please_select_books_used.hide()
    @continue.prop('disabled', false)
