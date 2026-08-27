(function() {
NewflowUi.EducatorComplete = class EducatorComplete {

  constructor() {
    _.bindAll(this, 'onSchoolNameChange', 'onRoleChange', 'onOtherChange', 'onHowUsingChange', 'onHowChosenChange', 'onBooksUsedChange', 'onBooksOfInterestChange', 'onTotalNumStudentsChange', 'onSubmit', 'attachBookUsedEvents');
    this.form = $('.signup-page.completed-step');

    // fields locators
    this.school_name = this.findOrLogNotFound(this.form, '.school-name-visible');

    this.completed_role = this.findOrLogNotFound(this.form, '.completed-role');
    this.other_specify = this.findOrLogNotFound(this.form, '.other-specify');

    this.how_chosen = this.findOrLogNotFound(this.form, '.how-chosen');
    this.how_using = this.findOrLogNotFound(this.form, '.how-using');

    this.books_used = this.findOrLogNotFound(this.form, '.books-used');
    this.books_of_interest = this.findOrLogNotFound(this.form, '.books-of-interest');
    this.expected_start_semester = this.findOrLogNotFound(this.form, '.expected-start-semester');
    this.expected_start_semester_select = this.findOrLogNotFound(this.expected_start_semester, 'select');
    this.total_num_students = this.findOrLogNotFound(this.form, '.total-num-students');

    // input fields locators
    this.school_name_input = this.findOrLogNotFound(this.school_name, 'input[type="text"]');

    this.completed_role_radio = this.findOrLogNotFound(this.completed_role, "input");
    this.other_input = this.findOrLogNotFound(this.other_specify, "input");

    this.how_chosen_radio = this.findOrLogNotFound(this.how_chosen, "input");
    this.how_using_radio = this.findOrLogNotFound(this.how_using, "input");

    // book selections (now using accordion checkboxes instead of selects)

    // total num students
    if (this.total_num_students.length) { this.total_num_students_input = this.findOrLogNotFound(this.total_num_students, 'input'); }
    this.total_num_students_label = this.findOrLogNotFound(this.form, '#total-num-students-label');
    this.total_num_students_alert = this.findOrLogNotFound(this.form, '.total-num-students-alert.newflow-mustdo-alert');

    // error messages locators
    this.please_fill_out_school = this.findOrLogNotFound(this.form, '.school-name.newflow-mustdo-alert');

    this.please_select_role = this.findOrLogNotFound(this.form, '.completed-role .role.newflow-mustdo-alert');
    this.please_fill_out_other = this.findOrLogNotFound(this.form, '.other.newflow-mustdo-alert');

    this.please_select_chosen = this.findOrLogNotFound(this.form, '.how-chosen .chosen.newflow-mustdo-alert');
    this.please_select_using = this.findOrLogNotFound(this.form, '.how-using .using.newflow-mustdo-alert');

    this.please_select_books_used = this.findOrLogNotFound(this.form, '.books-used .used.newflow-mustdo-alert');
    this.books_used_max = this.findOrLogNotFound(this.form, '.books-used .used-limit.newflow-mustdo-alert');
    this.please_select_books_of_interest = this.findOrLogNotFound(this.form, '.books-of-interest .books-of-interest.newflow-mustdo-alert');
    this.books_of_interest_max = this.findOrLogNotFound(this.form, '.books-of-interest .books-of-interest-limit.newflow-mustdo-alert');

    // event listeners
    this.school_name_input.on('input', this.onSchoolNameChange);

    this.completed_role_radio.change(this.onRoleChange);
    this.other_input.on('input', this.onOtherChange);

    this.how_chosen_radio.change(this.onHowChosenChange);
    this.how_using_radio.change(this.onHowUsingChange);

    if (this.total_num_students_input != null) {
      this.total_num_students_input.on('keyup change blur', this.onTotalNumStudentsChange);
    }

    this.findOrLogNotFound(this.form, 'form').submit(this.onSubmit);

    // Continue button
    this.continue = this.findOrLogNotFound(this.form, '#signup_form_submit_button');

    // Disable submitting initially
    this.continue.prop('disabled', true);

    // Hide these fields initially because they only show up depending on the form's state
    this.other_specify.hide();
    this.how_chosen.hide();
    this.how_using.hide();
    this.books_used.hide();
    this.books_of_interest.hide();
    this.expected_start_semester.hide();
    this.total_num_students.hide();

    // Hide all validations messages
    this.please_fill_out_school.hide();
    this.please_select_role.hide();
    this.total_num_students_alert.hide();

    this.please_select_books_used.hide();
    this.books_used_max.hide();
    this.please_select_books_of_interest.hide();
    this.books_of_interest_max.hide();

    // Wire up the book picker after locators are in place so that
    // initializeBookPickersState -> onBooks*Change can safely reference them.
    this.initBookPickers();
  }

  findOrLogNotFound(parent, selector) {
    const found = parent.find(selector);
    if (!found.length) {
      console.log('Couldn\'t find ', selector);
    }
    return found;
  }

  onSubmit(ev) {
    const school_name_valid = this.checkSchoolNameValid();

    const role_valid = this.checkRoleValid();
    const other_valid = this.checkOtherValid();

    const chosen_valid = this.checkChosenValid();
    const using_how_valid = this.checkUsingHowValid();

    const books_used_valid = this.checkBooksUsedValid();
    const books_used_valid_max = this.checkBooksUsedValidMax();
    const books_used_details_valid = this.checkBooksUsedDetailsValid();
    const books_of_interest_valid = this.checkBooksOfInterestValid();
    const books_of_interest_valid_max = this.checkBooksOfInterestValidMax();
    const total_num_students_valid = this.checkTotalNumStudentsValid();

    if (!(
        school_name_valid &&
        role_valid &&
        other_valid &&
        chosen_valid &&
        using_how_valid &&
        books_used_valid &&
        books_used_valid_max &&
        books_used_details_valid &&
        books_of_interest_valid_max &&
        books_of_interest_valid &&
        total_num_students_valid)) {
      return ev.preventDefault();
    }
  }

  checkSchoolNameValid() {
    if (document.getElementsByClassName('school-name-visible')[0] === undefined) { return true; }

    if (this.school_name_input.val()) {
      this.please_fill_out_school.hide();
      return true;
    } else {
      this.please_fill_out_school.show();
      return false;
    }
  }

  checkRoleValid() {
    if (this.completed_role_radio.is(":checked")) {
      this.please_select_role.hide();
      return true;
    } else {
      this.please_select_role.show();
      return false;
    }
  }

  checkChosenValid() {
    if (this.how_chosen_radio.is(":hidden")) { return true; }

    if (this.how_chosen_radio.is(":checked")) {
      this.please_select_chosen.hide();
      return true;
    } else {
      this.please_select_chosen.show();
      return false;
    }
  }

  checkBooksUsedDetailsValid() {
    const value = this.checkBookUsedTotalNumValid() && this.checkBookUsedHowValid();
    this.continue.prop('disabled', !value);
    return value;
  }

  checkBookUsedHowValid() {
    const selects = this.form.find(".how-using-book:visible select");

    const values = selects.map(function() {
      if ($(this).val()) {
        $(this).siblings('.how-using-book.newflow-mustdo-alert').hide();
        return true;
      } else {
        $(this).siblings('.how-using-book.newflow-mustdo-alert').show();
        return false;
      }
    });
    return values.get().every(value => value);
  }

  checkBookUsedTotalNumValid() {
    const inputs = this.form.find(".students-using-book:visible input");

    const values = inputs.map(function() {
      if ($(this).val()) {
        $(this).siblings('.num-using-book.newflow-mustdo-alert').hide();
        return true;
      } else {
        $(this).siblings('.num-using-book.newflow-mustdo-alert').show();
        return false;
      }
    });
    return values.get().every(value => value);
  }

  checkUsingHowValid() {
    if (this.how_using_radio.is(":hidden")) { return true; }

    if (this.how_using_radio.is(":checked")) {
      this.please_select_using.hide();
      return true;
    } else {
      this.please_select_using.show();
      return false;
    }
  }

  checkOtherValid() {
    if (this.other_input.is(":hidden")) { return true; }

    if (this.other_input.val()) {
      this.please_fill_out_other.hide();
      return true;
    } else {
      this.please_fill_out_other.show();
      return false;
    }
  }

  checkBooksUsedValid() {
    if (this.books_used.is(":hidden")) { return true; }

    if (this.getSelectedBooks('books_used').length > 0) {
      this.please_select_books_used.hide();
      return true;
    } else {
      this.please_select_books_used.show();
      return false;
    }
  }

  checkBooksUsedValidMax() {
    if (this.getSelectedBooks('books_used').length < 6) {
      this.books_used_max.hide();
      return true;
    } else {
      this.books_used_max.show();
      return false;
    }
  }

  checkBooksOfInterestValid() {
    if (this.books_of_interest.is(":hidden")) { return true; }

    if (this.getSelectedBooks('books_of_interest').length > 0) {
      this.please_select_books_of_interest.hide();
      return true;
    } else {
      this.please_select_books_of_interest.show();
      return false;
    }
  }

  checkBooksOfInterestValidMax() {
    if (this.getSelectedBooks('books_of_interest').length < 6) {
      this.books_of_interest_max.hide();
      return true;
    } else {
      this.books_of_interest_max.show();
      return false;
    }
  }

  onSchoolNameChange() {
    this.please_fill_out_school.hide();
    return this.onRoleChange();
  }

  onRoleChange() {
    this.please_select_role.hide();

    if ( this.findOrLogNotFound($(document), '#signup_educator_specific_role_instructor').is(':checked') && this.checkSchoolNameValid() ) {
      this.how_using.show();
      this.how_chosen.show();

      this.showBookUsedFields();

      this.other_specify.hide();
      this.books_used.hide();
      this.please_select_using.hide();
      this.please_select_chosen.hide();
      this.form.find('.students-using-book .newflow-mustdo-alert').hide();

      this.onHowUsingChange();
    } else if (this.findOrLogNotFound($(document), '#signup_educator_specific_role_researcher').is(':checked') && this.checkSchoolNameValid()) {
      this.how_chosen.show();
      this.how_using.show();

      this.other_specify.hide();
      this.books_used.hide();
      this.please_select_chosen.hide();
      this.please_select_using.hide();

      this.hideBookUsedFields();
      this.hideTotalNumStudents();

      this.onHowUsingChange();
    } else if ( this.findOrLogNotFound($(document), '#signup_educator_specific_role_administrator').is(':checked') && this.checkSchoolNameValid()) {
      this.how_chosen.show();
      this.how_using.show();

      this.other_specify.hide();
      this.books_used.hide();
      this.please_select_chosen.hide();
      this.please_select_using.hide();

      this.hideBookUsedFields();
      this.hideTotalNumStudents();

      this.onHowUsingChange();
    } else if ( this.findOrLogNotFound($(document), '#signup_educator_specific_role_other').is(':checked') ) {
      this.other_specify.show();
      this.showTotalNumStudents();

      this.books_used.hide();
      this.books_of_interest.hide();
      this.how_chosen.hide();
      this.how_using.hide();
      this.expected_start_semester.hide();
      this.expected_start_semester_select.val('');
      this.please_fill_out_other.hide();
    }

    this.updateTotalNumStudentsLabel();

    if (this.checkSchoolNameValid()) {
      return this.continue.prop('disabled', false);
    }
  }

  onOtherChange() {
    this.please_fill_out_other.hide();

    if (this.checkSchoolNameValid() && this.checkOtherValid()) {
      return this.continue.prop('disabled', false);
    }
  }

  onHowChosenChange() {
    return this.please_select_chosen.hide();
  }

  onHowUsingChange() {
    this.please_select_using.hide();

    if ( this.findOrLogNotFound($(document), '#signup_using_openstax_how_as_primary').is(':checked') ) {
      this.books_used.show();

      this.books_of_interest.hide();
      this.hideTotalNumStudents();
      this.updateBooksUsedFields(this.getSelectedBooks('books_used'));
      this.please_select_books_used.hide();
      this.please_select_books_of_interest.hide();
      return this.expected_start_semester.show();
    } else if ( this.findOrLogNotFound($(document), '#signup_using_openstax_how_as_recommending').is(':checked') ) {
      this.books_of_interest.show();
      this.showTotalNumStudents();

      this.books_used.hide();
      this.removeBooksUsedFields();
      this.please_select_books_used.hide();
      this.please_select_books_of_interest.hide();
      return this.expected_start_semester.show();
    } else if ( this.findOrLogNotFound($(document), '#signup_using_openstax_how_as_future').is(':checked') ) {
      this.books_of_interest.show();
      this.showTotalNumStudents();

      this.books_used.hide();
      this.removeBooksUsedFields();
      this.please_select_books_used.hide();
      this.please_select_books_of_interest.hide();
      this.expected_start_semester.hide();
      return this.expected_start_semester_select.val('');
    }
  }

  onBooksUsedChange() {
    this.updateBooksUsedFields(this.getSelectedBooks('books_used'));
    this.enforceMaxBooks('books_used');
    this.checkBooksUsedValidMax();
    return this.please_select_books_used.hide();
  }

  onBooksOfInterestChange() {
    this.enforceMaxBooks('books_of_interest');
    this.checkBooksOfInterestValidMax();

    this.please_select_books_of_interest.hide();
    return this.continue.prop('disabled', false);
  }

  removeBooksUsedFields() {
    const clonedNodes = document.querySelectorAll('div[data-book-name]');

    for (var node of clonedNodes) {
      node.parentNode.removeChild(node);
    }
  }

  updateBooksUsedFields(selected_books = []) {
    // Find all cloned nodes and remove ones that were deleted
    const clonedNodes = document.querySelectorAll('div[data-book-name]');

    for (var node of clonedNodes) {
      var bookName = node.getAttribute('data-book-name');
      if (!selected_books.includes(bookName)) {
        node.parentNode.removeChild(node);
      }
    }

    return (() => {
      const result = [];
      for (var book of selected_books) {
        if (!document.querySelector(`div[data-book-name='${book}']`)) {
          var templateNode = document.querySelector("div[data-template-id='used-book-info']");
          if (templateNode) {
            var clonedNode = templateNode.cloneNode(true);
            clonedNode.removeAttribute('data-template-id');
            clonedNode.setAttribute('data-book-name', book);

            // Use the checkbox value for identifiers/submission, but use the
            // human-readable title for visible text in the cloned UI.
            var coverCheckbox = this.form.find(`.book-tile-checkbox[value='${book}']`);
            var bookTitle = coverCheckbox.data('book-title') || book;

            var book_name_placeholders = clonedNode.querySelectorAll("[data-placeholder-id='used-book-name']");
            for (var book_name_placeholder of book_name_placeholders) {
              var book_name_node = document.createTextNode(bookTitle);
              book_name_placeholder.parentNode.replaceChild(book_name_node, book_name_placeholder);
            }

            // Set cover image from the book tile's data attribute
            var coverUrl = coverCheckbox.data('cover-url');
            bookTitle = coverCheckbox.data('book-title') || book;
            var coverImages = clonedNode.querySelectorAll("[data-placeholder-id='used-book-cover']");
            for (var coverImg of coverImages) {
              coverImg.setAttribute('src', coverUrl || '');
              coverImg.setAttribute('alt', bookTitle);
            }

            clonedNode.querySelectorAll('label, select, input').forEach(function(element) {
              element.removeAttribute('disabled');
              return Array.from(element.attributes)
              .filter(attr => attr.value.includes('%placeholder-book-name%'))
              .forEach(attr => attr.value = attr.value.replace('%placeholder-book-name%', book));
            });

            templateNode.insertAdjacentElement('afterend', clonedNode);
            this.attachBookUsedEvents(clonedNode);
            this.continue.prop('disabled', true);
          }
        }

        result.push(this.showBookUsedFields());
      }
      return result;
    })();
  }

  attachBookUsedEvents(parent) {
    const _this = this;
    const total_num_students = this.findOrLogNotFound($(parent), '.students-using-book');

    const total_num_students_input = this.findOrLogNotFound(total_num_students, 'input');
    total_num_students_input.on('keyup change blur', function() {
      const alert = $(parent).find('.students-using-book .num-using-book.newflow-mustdo-alert');
      _this.checkBooksUsedDetailsValid();
      if ($(this).val()) {
        return alert.hide();
      } else {
        return alert.show();
      }
    });

    const how_using_input = this.findOrLogNotFound($(parent), '.how-using-book select');
    return how_using_input.on('change blur', function() {
      const alert = $(parent).find('.how-using-book .using-book.newflow-mustdo-alert');
      _this.checkBooksUsedDetailsValid();
      if ($(this).val()) {
        return alert.hide();
      } else {
        return alert.show();
      }
    });
  }

  hideBookUsedFields() {
    this.form.find('.students-using-book').hide();
    return this.form.find('.how-using-book').hide();
  }

  showBookUsedFields() {
    this.form.find('.students-using-book').show();
    return this.form.find('.how-using-book').show();
  }

  showTotalNumStudents() {
    if (!(this.total_num_students != null ? this.total_num_students.length : undefined)) { return; }
    this.total_num_students.show();
    return this.updateTotalNumStudentsLabel();
  }

  hideTotalNumStudents() {
    if (!(this.total_num_students != null ? this.total_num_students.length : undefined)) { return; }
    this.total_num_students.hide();
    return (this.total_num_students_alert != null ? this.total_num_students_alert.hide() : undefined);
  }

  updateTotalNumStudentsLabel() {
    if (!(this.total_num_students_label != null ? this.total_num_students_label.length : undefined)) { return; }
    const isAdmin = this.findOrLogNotFound($(document), '#signup_educator_specific_role_administrator').is(':checked');
    const isOther = this.findOrLogNotFound($(document), '#signup_educator_specific_role_other').is(':checked');
    const container = this.total_num_students;
    if (isAdmin) {
      return this.total_num_students_label.text(container.data('label-admin'));
    } else if (isOther) {
      return this.total_num_students_label.text(container.data('label-other'));
    } else {
      return this.total_num_students_label.text(container.data('label-default'));
    }
  }

  onTotalNumStudentsChange() {
    return (this.total_num_students_alert != null ? this.total_num_students_alert.hide() : undefined);
  }

  checkTotalNumStudentsValid() {
    if (!(this.total_num_students != null ? this.total_num_students.length : undefined)) { return true; }
    if (this.total_num_students.is(":hidden")) { return true; }

    if (this.total_num_students_input != null ? this.total_num_students_input.val() : undefined) {
      if (this.total_num_students_alert != null) {
        this.total_num_students_alert.hide();
      }
      return true;
    } else {
      if (this.total_num_students_alert != null) {
        this.total_num_students_alert.show();
      }
      return false;
    }
  }

  // Book Picker Accordion methods

  initializeBookPickersState() {
    for (var fieldName of ['books_used', 'books_of_interest']) {
      var picker = this.form.find(`.book-picker[data-field-name='${fieldName}']`);
      if (!picker.length) { continue; }

      picker.find('.book-tile-checkbox').each(function() {
        return $(this).closest('.book-tile').toggleClass('selected', this.checked);
      });

      this.updateSelectedTags(fieldName);
    }

    this.onBooksUsedChange();
    return this.onBooksOfInterestChange();
  }

  initBookPickers() {
    const _this = this;

    // Accordion toggle: click subject header to expand/collapse
    this.form.on('click', '.book-picker-subject-header', function(e) {
      e.preventDefault();
      const body = $(this).siblings('.book-picker-subject-body');
      body.slideToggle(200);
      const icon = $(this).find('.fa');
      return icon.toggleClass('fa-caret-down fa-caret-up');
    });

    // Search filtering
    this.form.on('input', '.book-picker-search', function(e) {
      const query = $(this).val().toLowerCase();
      const picker = $(this).closest('.book-picker');

      // Toggle .search-hidden class on tiles (works even inside collapsed parents)
      picker.find('.book-tile').each(function() {
        const title = $(this).data('title').toLowerCase();
        if ((query.length > 0) && (title.indexOf(query) < 0)) {
          return $(this).addClass('search-hidden');
        } else {
          return $(this).removeClass('search-hidden');
        }
      });

      // Show/hide subjects based on matching books
      return picker.find('.book-picker-subject').each(function() {
        const matchingBooks = $(this).find('.book-tile:not(.search-hidden)').length;
        if (matchingBooks === 0) {
          return $(this).hide();
        } else {
          $(this).show();
          if (query.length > 0) {
            $(this).find('.book-picker-subject-body').show();
            return $(this).find('.fa').removeClass('fa-caret-down').addClass('fa-caret-up');
          } else {
            $(this).find('.book-picker-subject-body').hide();
            return $(this).find('.fa').removeClass('fa-caret-up').addClass('fa-caret-down');
          }
        }
      });
    });

    // Checkbox change handlers (delegated)
    this.form.on('change', '.book-picker[data-field-name="books_used"] .book-tile-checkbox', function() {
      const tile = $(this).closest('.book-tile');
      tile.toggleClass('selected', this.checked);
      _this.updateSelectedTags('books_used');
      return _this.onBooksUsedChange();
    });

    this.form.on('change', '.book-picker[data-field-name="books_of_interest"] .book-tile-checkbox', function() {
      const tile = $(this).closest('.book-tile');
      tile.toggleClass('selected', this.checked);
      _this.updateSelectedTags('books_of_interest');
      return _this.onBooksOfInterestChange();
    });

    // Tag removal (delegated)
    this.form.on('click', '.book-picker-tag .remove-tag', function(e) {
      e.preventDefault();
      const value = $(this).closest('.book-picker-tag').data('value');
      const fieldName = $(this).closest('.book-picker').data('field-name');
      const checkbox = _this.form.find(`.book-picker[data-field-name='${fieldName}'] .book-tile-checkbox[value='${value}']`);
      return checkbox.prop('checked', false).trigger('change');
    });

    return this.initializeBookPickersState();
  }

  getSelectedBooks(fieldName) {
    const checked = this.form.find(`.book-picker[data-field-name='${fieldName}'] .book-tile-checkbox:checked`);
    return checked.map(function() { return $(this).val(); }).get();
  }

  enforceMaxBooks(fieldName) {
    const picker = this.form.find(`.book-picker[data-field-name='${fieldName}']`);
    const selected = picker.find('.book-tile-checkbox:checked').length;
    if (selected >= 5) {
      return picker.find('.book-tile-checkbox:not(:checked)').each(function() {
        $(this).prop('disabled', true);
        return $(this).closest('.book-tile').addClass('disabled');
      });
    } else {
      return picker.find('.book-tile-checkbox:disabled').each(function() {
        $(this).prop('disabled', false);
        return $(this).closest('.book-tile').removeClass('disabled');
      });
    }
  }

  updateSelectedTags(fieldName) {
    const picker = this.form.find(`.book-picker[data-field-name='${fieldName}']`);
    const container = picker.find('.book-picker-selections');
    container.empty();
    return picker.find('.book-tile-checkbox:checked').each(function() {
      const title = $(this).data('book-title');
      const value = $(this).val();
      const tag = $('<span class="book-picker-tag"></span>').attr('data-value', value);
      const removeButton = $('<button type="button" class="remove-tag"></button>')
        .attr('aria-label', `Remove ${title}`)
        .text('×');
      tag.text(title);
      tag.append(' ');
      tag.append(removeButton);
      return container.append(tag);
    });
  }
};
}).call(this);
