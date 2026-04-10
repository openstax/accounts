class NewflowUi.EducatorComplete

  constructor: ->
    _.bindAll(@, 'onSchoolNameChange', 'onRoleChange', 'onOtherChange', 'onHowUsingChange', 'onHowChosenChange', 'onBooksUsedChange', 'onBooksOfInterestChange', 'onTotalNumStudentsChange', 'onSubmit', 'attachBookUsedEvents')
    @form = $('.signup-page.completed-step')
    @initBookPickers()

    # fields locators
    @school_name = @findOrLogNotFound(@form, '.school-name-visible')

    @completed_role = @findOrLogNotFound(@form, '.completed-role')
    @other_specify = @findOrLogNotFound(@form, '.other-specify')

    @how_chosen = @findOrLogNotFound(@form, '.how-chosen')
    @how_using = @findOrLogNotFound(@form, '.how-using')

    @books_used = @findOrLogNotFound(@form, '.books-used')
    @books_of_interest = @findOrLogNotFound(@form, '.books-of-interest')
    @total_num_students = @findOrLogNotFound(@form, '.total-num-students')

    # input fields locators
    @school_name_input = @findOrLogNotFound(@school_name, 'input')

    @completed_role_radio = @findOrLogNotFound(@completed_role, "input")
    @other_input = @findOrLogNotFound(@other_specify, "input")

    @how_chosen_radio = @findOrLogNotFound(@how_chosen, "input")
    @how_using_radio = @findOrLogNotFound(@how_using, "input")

    # book selections (now using accordion checkboxes instead of selects)

    # total num students
    @total_num_students_input = @findOrLogNotFound(@total_num_students, 'input') if @total_num_students.length
    @total_num_students_label = @findOrLogNotFound(@form, '#total-num-students-label')
    @total_num_students_alert = @findOrLogNotFound(@form, '.total-num-students-alert.newflow-mustdo-alert')

    # error messages locators
    @please_fill_out_school = @findOrLogNotFound(@form, '.school-name.newflow-mustdo-alert')

    @please_select_role = @findOrLogNotFound(@form, '.completed-role .role.newflow-mustdo-alert')
    @please_fill_out_other = @findOrLogNotFound(@form, '.other.newflow-mustdo-alert')

    @please_select_chosen = @findOrLogNotFound(@form, '.how-chosen .chosen.newflow-mustdo-alert')
    @please_select_using = @findOrLogNotFound(@form, '.how-using .using.newflow-mustdo-alert')

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

    @total_num_students_input?.on('keyup change blur', @onTotalNumStudentsChange)

    @findOrLogNotFound(@form, 'form').submit(@onSubmit)

    # Continue button
    @continue = @findOrLogNotFound(@form, '#signup_form_submit_button')

    # Disable submitting initially
    @continue.prop('disabled', true)

    # Hide these fields initially because they only show up depending on the form's state
    @other_specify.hide()
    @how_chosen.hide()
    @how_using.hide()
    @books_used.hide()
    @books_of_interest.hide()
    @total_num_students?.hide()

    # Hide all validations messages
    @please_fill_out_school.hide()
    @please_select_role.hide()
    @total_num_students_alert?.hide()

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

  onSubmit: (ev) ->
    school_name_valid = @checkSchoolNameValid()

    role_valid = @checkRoleValid()
    other_valid = @checkOtherValid()

    chosen_valid = @checkChosenValid()
    using_how_valid = @checkUsingHowValid()

    books_used_valid = @checkBooksUsedValid()
    books_used_valid_max = @checkBooksUsedValidMax()
    books_used_details_valid = @checkBooksUsedValid()
    books_of_interest_valid = @checkBooksOfInterestValid()
    books_of_interest_valid_max = @checkBooksOfInterestValidMax()
    total_num_students_valid = @checkTotalNumStudentsValid()

    if not (
        school_name_valid and
        role_valid and
        other_valid and
        chosen_valid and
        using_how_valid and
        books_used_valid and
        books_used_valid_max and
        books_used_details_valid and
        books_of_interest_valid_max and
        books_of_interest_valid and
        total_num_students_valid)
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

  checkBooksUsedDetailsValid: () ->
    value = @checkBookUsedTotalNumValid() && @checkBookUsedHowValid()
    @continue.prop('disabled', !value)
    value

  checkBookUsedHowValid: () ->
    selects = @form.find(".how-using-book:visible select")

    values = selects.map ->
      if $(this).val()
        $(this).siblings('.how-using-book.newflow-mustdo-alert').hide()
        true
      else
        $(this).siblings('.how-using-book.newflow-mustdo-alert').show()
        false
    return values.get().every (value) -> value

  checkBookUsedTotalNumValid: () ->
    inputs = @form.find(".students-using-book:visible input")

    values = inputs.map ->
      if $(this).val()
        $(this).siblings('.num-using-book.newflow-mustdo-alert').hide()
        true
      else
        $(this).siblings('.num-using-book.newflow-mustdo-alert').show()
        false
    return values.get().every (value) -> value

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

    if @getSelectedBooks('books_used').length > 0
      @please_select_books_used.hide()
      true
    else
      @please_select_books_used.show()
      false

  checkBooksUsedValidMax: () ->
    if @getSelectedBooks('books_used').length < 6
      @books_used_max.hide()
      true
    else
      @books_used_max.show()
      false

  checkBooksOfInterestValid: () ->
    return true if @books_of_interest.is(":hidden")

    if @getSelectedBooks('books_of_interest').length > 0
      @please_select_books_of_interest.hide()
      true
    else
      @please_select_books_of_interest.show()
      false

  checkBooksOfInterestValidMax: () ->
    if @getSelectedBooks('books_of_interest').length < 6
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

      @showBookUsedFields()

      @other_specify.hide()
      @books_used.hide()
      @please_select_using.hide()
      @please_select_chosen.hide()
      @form.find('.students-using-book .newflow-mustdo-alert').hide()

      @onHowUsingChange()
    else if (@findOrLogNotFound($(document), '#signup_educator_specific_role_researcher').is(':checked') && @checkSchoolNameValid())
      @how_chosen.show()
      @how_using.show()

      @other_specify.hide()
      @books_used.hide()
      @please_select_chosen.hide()
      @please_select_using.hide()

      @hideBookUsedFields()
      @hideTotalNumStudents()

      @onHowUsingChange()
    else if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_administrator').is(':checked') && @checkSchoolNameValid())
      @how_chosen.show()
      @how_using.show()

      @other_specify.hide()
      @books_used.hide()
      @please_select_chosen.hide()
      @please_select_using.hide()

      @hideBookUsedFields()
      @hideTotalNumStudents()

      @onHowUsingChange()
    else if ( @findOrLogNotFound($(document), '#signup_educator_specific_role_other').is(':checked') )
      @other_specify.show()

      @books_used.hide()
      @books_of_interest.hide()
      @how_chosen.hide()
      @hideTotalNumStudents()
      @how_using.hide()
      @please_fill_out_other.hide()

    @updateTotalNumStudentsLabel()

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
      @hideTotalNumStudents()
      @updateBooksUsedFields(@getSelectedBooks('books_used'))
      @please_select_books_used.hide()
      @please_select_books_of_interest.hide()
    else if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_recommending').is(':checked') )
      @books_of_interest.show()
      @showTotalNumStudents()

      @books_used.hide()
      @removeBooksUsedFields()
      @please_select_books_used.hide()
      @please_select_books_of_interest.hide()
    else if ( @findOrLogNotFound($(document), '#signup_using_openstax_how_as_future').is(':checked') )
      @books_of_interest.show()
      @showTotalNumStudents()

      @books_used.hide()
      @removeBooksUsedFields()
      @please_select_books_used.hide()
      @please_select_books_of_interest.hide()

  onBooksUsedChange: ->
    @updateBooksUsedFields(@getSelectedBooks('books_used'))
    @enforceMaxBooks('books_used')
    @checkBooksUsedValidMax()
    @please_select_books_used.hide()

  onBooksOfInterestChange: ->
    @enforceMaxBooks('books_of_interest')
    @checkBooksOfInterestValidMax()

    @please_select_books_of_interest.hide()
    @continue.prop('disabled', false)

  removeBooksUsedFields: () ->
    clonedNodes = document.querySelectorAll('div[data-book-name]')

    for node in clonedNodes
      node.parentNode.removeChild(node)

  updateBooksUsedFields: (selected_books = []) ->
    # Find all cloned nodes and remove ones that were deleted
    clonedNodes = document.querySelectorAll('div[data-book-name]')

    for node in clonedNodes
      bookName = node.getAttribute('data-book-name')
      if bookName not in selected_books
        node.parentNode.removeChild(node)

    for book in selected_books
      if not document.querySelector("div[data-book-name='#{book}']")
        templateNode = document.querySelector("div[data-template-id='used-book-info']")
        if templateNode
          clonedNode = templateNode.cloneNode(true)
          clonedNode.removeAttribute('data-template-id')
          clonedNode.setAttribute('data-book-name', book)

          book_name_placeholders = clonedNode.querySelectorAll("[data-placeholder-id='used-book-name']")
          for book_name_placeholder in book_name_placeholders
            book_name_node = document.createTextNode(book)
            book_name_placeholder.parentNode.replaceChild(book_name_node, book_name_placeholder)

          # Set cover image from the book tile's data attribute
          coverCheckbox = @form.find(".book-tile-checkbox[value='#{book}']")
          coverUrl = coverCheckbox.data('cover-url')
          coverImages = clonedNode.querySelectorAll("[data-placeholder-id='used-book-cover']")
          for coverImg in coverImages
            coverImg.setAttribute('src', coverUrl || '')
            coverImg.setAttribute('alt', book)

          clonedNode.querySelectorAll('label, select, input').forEach (element) ->
            element.removeAttribute('disabled')
            Array.from(element.attributes)
            .filter((attr) -> attr.value.includes('%placeholder-book-name%'))
            .forEach((attr) -> attr.value = attr.value.replace('%placeholder-book-name%', book))

          templateNode.insertAdjacentElement('afterend', clonedNode)
          @attachBookUsedEvents(clonedNode)
          @continue.prop('disabled', true)

      @showBookUsedFields()

  attachBookUsedEvents: (parent) ->
    _this = @
    total_num_students = @findOrLogNotFound($(parent), '.students-using-book')

    total_num_students_input = @findOrLogNotFound(total_num_students, 'input')
    total_num_students_input.on 'keyup change blur', ->
      alert = $(parent).find('.students-using-book .num-using-book.newflow-mustdo-alert')
      _this.checkBooksUsedDetailsValid()
      if $(this).val()
        alert.hide()
      else
        alert.show()

    how_using_input = @findOrLogNotFound($(parent), '.how-using-book select')
    how_using_input.on 'change blur', ->
      alert = $(parent).find('.how-using-book .using-book.newflow-mustdo-alert')
      _this.checkBooksUsedDetailsValid()
      if $(this).val()
        alert.hide()
      else
        alert.show()

  hideBookUsedFields: ->
    @form.find('.students-using-book').hide()
    @form.find('.how-using-book').hide()

  showBookUsedFields: ->
    @form.find('.students-using-book').show()
    @form.find('.how-using-book').show()

  showTotalNumStudents: ->
    return unless @total_num_students?.length
    @total_num_students.show()
    @updateTotalNumStudentsLabel()

  hideTotalNumStudents: ->
    return unless @total_num_students?.length
    @total_num_students.hide()
    @total_num_students_alert?.hide()

  updateTotalNumStudentsLabel: ->
    return unless @total_num_students_label?.length
    isAdmin = @findOrLogNotFound($(document), '#signup_educator_specific_role_administrator').is(':checked')
    container = @total_num_students
    if isAdmin
      @total_num_students_label.text(container.data('label-admin'))
    else
      @total_num_students_label.text(container.data('label-default'))

  onTotalNumStudentsChange: ->
    @total_num_students_alert?.hide()

  checkTotalNumStudentsValid: () ->
    return true unless @total_num_students?.length
    return true if @total_num_students.is(":hidden")

    if @total_num_students_input?.val()
      @total_num_students_alert?.hide()
      true
    else
      @total_num_students_alert?.show()
      false

  # Book Picker Accordion methods

  initBookPickers: ->
    _this = @

    # Accordion toggle: click subject header to expand/collapse
    @form.on 'click', '.book-picker-subject-header', (e) ->
      e.preventDefault()
      body = $(this).siblings('.book-picker-subject-body')
      body.slideToggle(200)
      icon = $(this).find('.fa')
      icon.toggleClass('fa-caret-down fa-caret-up')

    # Search filtering
    @form.on 'input', '.book-picker-search', (e) ->
      query = $(this).val().toLowerCase()
      picker = $(this).closest('.book-picker')

      # Toggle .search-hidden class on tiles (works even inside collapsed parents)
      picker.find('.book-tile').each ->
        title = $(this).data('title').toLowerCase()
        if query.length > 0 && title.indexOf(query) < 0
          $(this).addClass('search-hidden')
        else
          $(this).removeClass('search-hidden')

      # Show/hide subjects based on matching books
      picker.find('.book-picker-subject').each ->
        matchingBooks = $(this).find('.book-tile:not(.search-hidden)').length
        if matchingBooks == 0
          $(this).hide()
        else
          $(this).show()
          if query.length > 0
            $(this).find('.book-picker-subject-body').show()
            $(this).find('.fa').removeClass('fa-caret-down').addClass('fa-caret-up')
          else
            $(this).find('.book-picker-subject-body').hide()
            $(this).find('.fa').removeClass('fa-caret-up').addClass('fa-caret-down')

    # Checkbox change handlers (delegated)
    @form.on 'change', '.book-picker[data-field-name="books_used"] .book-tile-checkbox', ->
      tile = $(this).closest('.book-tile')
      tile.toggleClass('selected', this.checked)
      _this.updateSelectedTags('books_used')
      _this.onBooksUsedChange()

    @form.on 'change', '.book-picker[data-field-name="books_of_interest"] .book-tile-checkbox', ->
      tile = $(this).closest('.book-tile')
      tile.toggleClass('selected', this.checked)
      _this.updateSelectedTags('books_of_interest')
      _this.onBooksOfInterestChange()

    # Tag removal (delegated)
    @form.on 'click', '.book-picker-tag .remove-tag', (e) ->
      e.preventDefault()
      value = $(this).closest('.book-picker-tag').data('value')
      fieldName = $(this).closest('.book-picker').data('field-name')
      checkbox = _this.form.find(".book-picker[data-field-name='#{fieldName}'] .book-tile-checkbox[value='#{value}']")
      checkbox.prop('checked', false).trigger('change')

  getSelectedBooks: (fieldName) ->
    checked = @form.find(".book-picker[data-field-name='#{fieldName}'] .book-tile-checkbox:checked")
    checked.map(-> $(this).val()).get()

  enforceMaxBooks: (fieldName) ->
    picker = @form.find(".book-picker[data-field-name='#{fieldName}']")
    selected = picker.find('.book-tile-checkbox:checked').length
    if selected >= 5
      picker.find('.book-tile-checkbox:not(:checked)').each ->
        $(this).prop('disabled', true)
        $(this).closest('.book-tile').addClass('disabled')
    else
      picker.find('.book-tile-checkbox:disabled').each ->
        $(this).prop('disabled', false)
        $(this).closest('.book-tile').removeClass('disabled')

  updateSelectedTags: (fieldName) ->
    picker = @form.find(".book-picker[data-field-name='#{fieldName}']")
    container = picker.find('.book-picker-selections')
    container.empty()
    picker.find('.book-tile-checkbox:checked').each ->
      title = $(this).data('book-title')
      value = $(this).val()
      tag = $('<span class="book-picker-tag"></span>').attr('data-value', value)
      tag.text(title)
      tag.append(' <span class="remove-tag">&times;</span>')
      container.append(tag)
