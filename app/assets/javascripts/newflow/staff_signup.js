// Vanilla-JS helpers for the staff "Tell us about your work" signup step
// (role "Other" reveal, school-match confirmation, and the book picker
// accordion also used on the educator profile form).
//
// Bound synchronously from the constructor (not inside $(document).ready()):
// this runs from an inline <script> at the bottom of the view, after the
// elements it touches already exist in the parsed DOM, so there's no gap to
// race the way there was for the ready()-bound handler fixed in newflow_ui.js
// (see the "Fix pose_terms flake" commit) — but we still avoid ready() here
// on principle, to not reintroduce that class of bug.
(function() {
  'use strict';

  function StaffDetails() {
    this.bindRoleOther();
    this.bindSchoolMatchConfirmation();
    this.bindBookPicker();
  }

  StaffDetails.prototype.bindRoleOther = function() {
    var fieldset = document.querySelector('.staff-role-fieldset');
    if (!fieldset) { return; }

    var otherField = fieldset.querySelector('.other-specify');
    if (!otherField) { return; }

    function sync() {
      var checked = fieldset.querySelector('input[type="radio"]:checked');
      otherField.style.display = (checked && checked.value === 'other') ? '' : 'none';
    }

    fieldset.addEventListener('change', function(event) {
      if (event.target && event.target.type === 'radio') { sync(); }
    });

    sync();
  };

  StaffDetails.prototype.bindSchoolMatchConfirmation = function() {
    var container = document.querySelector('.school-autocomplete');
    if (!container) { return; }

    var hiddenId = container.querySelector('input[type="hidden"]');
    var matched = container.querySelector('.school-matched');
    if (!hiddenId || !matched) { return; }

    var prefix = matched.getAttribute('data-matched-prefix') || 'Matched';

    hiddenId.addEventListener('school:selected', function(event) {
      var school = event.detail || {};
      var location = [school.city, school.state].filter(Boolean).join(', ');
      var label = school.name + (location ? ', ' + location : '');
      matched.textContent = '✓ ' + prefix + ' — ' + label;
      matched.hidden = false;
    });

    hiddenId.addEventListener('school:cleared', function() {
      matched.hidden = true;
      matched.textContent = '';
    });
  };

  // Same accordion/search/tag markup as the educator profile form's book
  // picker (app/views/newflow/educator_signup/_book_picker.html.erb), reused
  // here as-is. NewflowUi.EducatorComplete wires the equivalent behavior for
  // that form, but it also drives educator-only fields (per-book student
  // counts, "how are you using this book" selects) that don't apply to staff,
  // so we bind the picker independently here instead of instantiating it.
  StaffDetails.prototype.bindBookPicker = function() {
    var picker = document.querySelector('.book-picker');
    if (!picker) { return; }

    picker.addEventListener('click', function(event) {
      var header = event.target.closest && event.target.closest('.book-picker-subject-header');
      if (!header) { return; }

      event.preventDefault();
      var body = header.parentElement.querySelector('.book-picker-subject-body');
      var expanded = header.getAttribute('aria-expanded') === 'true';
      header.setAttribute('aria-expanded', (!expanded).toString());
      if (body) {
        body.style.display = expanded ? 'none' : '';
        body.setAttribute('aria-hidden', expanded.toString());
      }
      var icon = header.querySelector('.fa');
      if (icon) {
        icon.classList.toggle('fa-caret-down', expanded);
        icon.classList.toggle('fa-caret-up', !expanded);
      }
    });

    var search = picker.querySelector('.book-picker-search');
    if (search) {
      search.addEventListener('input', function() {
        var query = search.value.trim().toLowerCase();
        var subjects = picker.querySelectorAll('.book-picker-subject');

        subjects.forEach(function(subject) {
          var tiles = subject.querySelectorAll('.book-tile');
          var matches = 0;

          tiles.forEach(function(tile) {
            var title = (tile.getAttribute('data-title') || '').toLowerCase();
            var hidden = query.length > 0 && title.indexOf(query) < 0;
            tile.classList.toggle('search-hidden', hidden);
            if (!hidden) { matches += 1; }
          });

          subject.style.display = matches === 0 ? 'none' : '';

          var body = subject.querySelector('.book-picker-subject-body');
          var header = subject.querySelector('.book-picker-subject-header');
          if (body && header && query.length > 0) {
            body.style.display = '';
            header.setAttribute('aria-expanded', 'true');
          }
        });
      });
    }

    picker.addEventListener('change', function(event) {
      if (!event.target.classList || !event.target.classList.contains('book-tile-checkbox')) { return; }
      var tile = event.target.closest('.book-tile');
      if (tile) { tile.classList.toggle('selected', event.target.checked); }
      updateSelectedTags(picker);
    });

    picker.addEventListener('click', function(event) {
      var removeButton = event.target.closest && event.target.closest('.book-picker-tag .remove-tag');
      if (!removeButton) { return; }

      event.preventDefault();
      var value = removeButton.closest('.book-picker-tag').getAttribute('data-value');
      var checkbox = picker.querySelector('.book-tile-checkbox[value="' + value + '"]');
      if (checkbox) {
        checkbox.checked = false;
        var tile = checkbox.closest('.book-tile');
        if (tile) { tile.classList.remove('selected'); }
        updateSelectedTags(picker);
      }
    });

    updateSelectedTags(picker);
  };

  function updateSelectedTags(picker) {
    var container = picker.querySelector('.book-picker-selections');
    if (!container) { return; }

    container.innerHTML = '';
    var checked = picker.querySelectorAll('.book-tile-checkbox:checked');

    checked.forEach(function(checkbox) {
      var title = checkbox.getAttribute('data-book-title');
      var value = checkbox.value;

      var tag = document.createElement('span');
      tag.className = 'book-picker-tag';
      tag.setAttribute('data-value', value);
      tag.appendChild(document.createTextNode(title + ' '));

      var removeButton = document.createElement('button');
      removeButton.type = 'button';
      removeButton.className = 'remove-tag';
      removeButton.setAttribute('aria-label', 'Remove ' + title);
      removeButton.textContent = '×';
      tag.appendChild(removeButton);

      container.appendChild(tag);
    });
  }

  NewflowUi.StaffDetails = StaffDetails;
})();
