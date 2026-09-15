// Progressive enhancement for the 6-digit email-verification PIN field
// (educator + student signup "Check your email" step).
//
// Markup contract: a `.pin-field` container wraps one real text input
// (class `.pin-field__input`) plus its label/placeholder/error markup. That
// real input is what the form actually submits, and it's the only element
// no-JS browsers and feature specs (Capybara fills it directly by id) ever
// see. When this script runs it builds 6 single-character boxes next to it,
// hides the real input off-screen — never display:none/visibility:hidden,
// so it stays a normal, interactable form field for automated browsers and
// anything else that targets it directly — and keeps the two in sync in
// both directions (typing in a box updates the real input; the real input
// changing, e.g. via Capybara's fill_in or SMS autofill, redistributes into
// the boxes).
(function() {
  'use strict';

  var PIN_LENGTH = 6;

  function digitsOnly(value) {
    return (value || '').replace(/[^0-9]/g, '');
  }

  function enhance(container) {
    var realInput = container.querySelector('.pin-field__input');
    if (!realInput || container.querySelector('.pin-field__boxes')) { return; }

    var boxesWrap = document.createElement('div');
    boxesWrap.className = 'pin-field__boxes';

    var boxes = [];
    var i;
    for (i = 0; i < PIN_LENGTH; i++) {
      var box = document.createElement('input');
      box.type = 'text';
      box.className = 'pin-field__box';
      box.setAttribute('inputmode', 'numeric');
      box.setAttribute('pattern', '[0-9]*');
      box.setAttribute('maxlength', '1');
      box.setAttribute('autocomplete', 'off');
      box.setAttribute(
        'aria-label',
        'Digit ' + (i + 1) + ' of ' + PIN_LENGTH + ' of your verification code'
      );
      boxesWrap.appendChild(box);
      boxes.push(box);
    }

    realInput.parentNode.insertBefore(boxesWrap, realInput.nextSibling);

    function syncRealInputFromBoxes() {
      var combined = '';
      for (var j = 0; j < boxes.length; j++) {
        combined += boxes[j].value;
      }
      realInput.value = combined;
    }

    // Fills the boxes from a digit string and returns the box that should
    // receive focus afterwards (the first empty one, or the last box if the
    // code is complete).
    function distributeToBoxes(digits) {
      var j;
      for (j = 0; j < boxes.length; j++) {
        boxes[j].value = digits.charAt(j) || '';
      }
      syncRealInputFromBoxes();

      for (j = 0; j < boxes.length; j++) {
        if (boxes[j].value === '') { return boxes[j]; }
      }
      return boxes[boxes.length - 1];
    }

    function handleInput(e) {
      var box = e.target;
      var idx = boxes.indexOf(box);
      var digits = digitsOnly(box.value);

      if (digits.length > 1) {
        // Autofill / predictive text dropped the whole code into one box.
        distributeToBoxes(digits).focus();
        return;
      }

      box.value = digits;
      syncRealInputFromBoxes();

      if (digits !== '' && idx < boxes.length - 1) {
        boxes[idx + 1].focus();
      }
    }

    function handleKeydown(e) {
      var box = e.target;
      var idx = boxes.indexOf(box);
      var isBackspace = e.key === 'Backspace' || e.keyCode === 8;

      if (isBackspace && box.value === '' && idx > 0) {
        e.preventDefault();
        boxes[idx - 1].value = '';
        boxes[idx - 1].focus();
        syncRealInputFromBoxes();
      }
    }

    function handlePaste(e) {
      var clipboard = e.clipboardData || window.clipboardData;
      var digits = digitsOnly(clipboard ? clipboard.getData('text') : '');
      if (digits === '') { return; }

      e.preventDefault();
      distributeToBoxes(digits).focus();
    }

    for (i = 0; i < boxes.length; i++) {
      boxes[i].addEventListener('input', handleInput);
      boxes[i].addEventListener('keydown', handleKeydown);
      boxes[i].addEventListener('paste', handlePaste);
    }

    // Keep in sync the other direction too: Capybara's fill_in, password
    // managers, and mobile SMS autofill all set the real input's value
    // directly rather than typing into the boxes.
    realInput.addEventListener('input', function() {
      distributeToBoxes(digitsOnly(realInput.value));
    });

    container.className += ' pin-field--enhanced';
    realInput.setAttribute('aria-hidden', 'true');
    realInput.setAttribute('tabindex', '-1');

    // Reflect any value the server already put in the field (e.g. a
    // re-rendered form after a validation error) in the boxes on load.
    if (realInput.value !== '') {
      distributeToBoxes(digitsOnly(realInput.value)).focus();
    } else {
      boxes[0].focus();
    }
  }

  document.addEventListener('DOMContentLoaded', function() {
    var containers = document.querySelectorAll('.pin-field');
    for (var i = 0; i < containers.length; i++) {
      enhance(containers[i]);
    }
  });
})();
