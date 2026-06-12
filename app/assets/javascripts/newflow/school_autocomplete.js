// School-name autocomplete combobox backed by GET /i/schools.
//
// Markup contract: attach() is given a container element holding one text
// input (the visible school name field) and one hidden input (the school id).
// Picking a suggestion fills the text input with the canonical school name and
// sets the hidden id; any subsequent edit clears the hidden id. The last row
// always offers using the typed text as-is (free text => hidden id stays empty).
// The container may set data-use-as-entered-label, with "{school}" as the
// placeholder for the typed text.
(function() {
  'use strict';

  var ENDPOINT = '/i/schools';
  var DEBOUNCE_MS = 300;
  var MIN_QUERY_LENGTH = 2;

  function attach(containerSelector) {
    var container = document.querySelector(containerSelector);
    if (!container) { return; }

    var input = container.querySelector('input[type="text"]');
    var hiddenId = container.querySelector('input[type="hidden"]');
    var useAsEnteredLabel =
      container.getAttribute('data-use-as-entered-label') || 'Use "{school}"';

    var listbox = document.createElement('ul');
    listbox.className = 'school-autocomplete-results';
    listbox.id = input.id + '-results';
    listbox.setAttribute('role', 'listbox');
    listbox.hidden = true;
    container.appendChild(listbox);

    input.setAttribute('role', 'combobox');
    input.setAttribute('aria-autocomplete', 'list');
    input.setAttribute('aria-expanded', 'false');
    input.setAttribute('aria-controls', listbox.id);
    input.setAttribute('autocomplete', 'off');

    var state = { schools: [], query: '', activeIndex: -1, abortController: null };

    var debouncedFetch = _.debounce(fetchSchools, DEBOUNCE_MS);

    input.addEventListener('input', function() {
      hiddenId.value = '';
      var query = input.value.trim();
      if (query.length < MIN_QUERY_LENGTH) {
        close();
        return;
      }
      debouncedFetch(query);
    });

    input.addEventListener('keydown', function(event) {
      if (listbox.hidden) { return; }

      if (event.key === 'ArrowDown') {
        event.preventDefault();
        setActive(Math.min(state.activeIndex + 1, optionCount() - 1));
      } else if (event.key === 'ArrowUp') {
        event.preventDefault();
        setActive(state.activeIndex <= 0 ? -1 : state.activeIndex - 1);
      } else if (event.key === 'Enter') {
        if (state.activeIndex >= 0) {
          event.preventDefault();
          selectIndex(state.activeIndex);
        }
      } else if (event.key === 'Escape') {
        close();
      }
    });

    // Free text is a valid end state: leaving the field just closes the list.
    input.addEventListener('blur', function() {
      // Delay so a mousedown selection on an option wins over the blur.
      setTimeout(close, 150);
    });

    function fetchSchools(query) {
      if (state.abortController) { state.abortController.abort(); }
      state.abortController = new AbortController();

      fetch(ENDPOINT + '?q=' + encodeURIComponent(query), {
        signal: state.abortController.signal
      })
        .then(function(response) { return response.ok ? response.json() : []; })
        .then(function(schools) { render(schools, query); })
        .catch(function(error) {
          // Degrade to free text: on failure show only the use-as-entered row.
          if (error.name !== 'AbortError') { render([], query); }
        });
    }

    function render(schools, query) {
      // Ignore stale responses (field cleared, edited, or no longer focused).
      if (input.value.trim() !== query || document.activeElement !== input) {
        return;
      }

      state.schools = schools;
      state.query = query;
      state.activeIndex = -1;
      listbox.innerHTML = '';

      schools.forEach(function(school, index) {
        var li = buildOption(index);

        var name = document.createElement('span');
        name.className = 'school-autocomplete-name';
        name.textContent = school.name;
        li.appendChild(name);

        var location = [school.city, school.state].filter(Boolean).join(', ');
        if (location) {
          var locationEl = document.createElement('span');
          locationEl.className = 'school-autocomplete-location';
          locationEl.textContent = location;
          li.appendChild(locationEl);
        }

        listbox.appendChild(li);
      });

      var footer = buildOption(schools.length);
      footer.className += ' school-autocomplete-use-as-entered';
      footer.textContent = useAsEnteredLabel.replace('{school}', query);
      listbox.appendChild(footer);

      listbox.hidden = false;
      input.setAttribute('aria-expanded', 'true');
    }

    function buildOption(index) {
      var li = document.createElement('li');
      li.id = listbox.id + '-option-' + index;
      li.setAttribute('role', 'option');
      li.setAttribute('aria-selected', 'false');
      // mousedown (not click) so selection beats the input's blur handler.
      li.addEventListener('mousedown', function(event) {
        event.preventDefault();
        selectIndex(index);
      });
      li.addEventListener('mousemove', function() { setActive(index); });
      return li;
    }

    function optionCount() {
      return state.schools.length + 1; // + the use-as-entered row
    }

    function setActive(index) {
      state.activeIndex = index;
      var options = listbox.children;
      for (var i = 0; i < options.length; i++) {
        options[i].classList.toggle('active', i === index);
        options[i].setAttribute('aria-selected', i === index ? 'true' : 'false');
      }
      if (index >= 0 && options[index]) {
        input.setAttribute('aria-activedescendant', options[index].id);
        options[index].scrollIntoView({ block: 'nearest' });
      } else {
        input.removeAttribute('aria-activedescendant');
      }
    }

    function selectIndex(index) {
      var school = state.schools[index];
      if (school) {
        input.value = school.name;
        hiddenId.value = school.id;
      } else {
        // The use-as-entered row: keep the typed text, no school link.
        hiddenId.value = '';
      }
      close();
    }

    function close() {
      listbox.hidden = true;
      listbox.innerHTML = '';
      state.schools = [];
      state.activeIndex = -1;
      input.setAttribute('aria-expanded', 'false');
      input.removeAttribute('aria-activedescendant');
    }
  }

  window.OxSchoolAutocomplete = { attach: attach };
})();
