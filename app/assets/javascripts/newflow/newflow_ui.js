(function() {
const NewflowUi = (function() {
  return {
    disableButton(selector) {
      $(selector).attr('disabled', 'disabled');
      return $(selector).addClass('ui-state-disabled ui-button-disabled');
    },

    enableButton(selector) {
      $(selector).removeAttr('disabled');
      $(selector).removeClass('ui-state-disabled ui-button-disabled');
      return $(selector).button();
    },

    renderAndOpenDialog(html_id, content, modal_options = {}) {
      if ($('#' + html_id).exists()) { $('#' + html_id).remove(); }
      $("#application-body").append(content);
      $('#' + html_id).modal(modal_options);

      // Code to center the dialog
      const modalDialog = $('#' + html_id + ' .modal-dialog');
      const modalHeight = modalDialog.outerHeight();
      const userScreenHeight = window.outerHeight;

      if (modalHeight > userScreenHeight) {
        return modalDialog.css('overflow', 'auto'); //set to overflow if no fit
      } else {
        return modalDialog.css('margin-top', //center it if it does fit
                        ((userScreenHeight / 2) - (modalHeight / 2)));
      }
    },

    checkCheckedButton(targetSelector, sourceSelector) {
      if ($(sourceSelector).is(':checked')) {
        return this.enableButton(targetSelector);
      } else {
        return this.disableButton(targetSelector);
      }
    },

    enableOnChecked(targetSelector, sourceSelector) {
      const check = () => {
        return this.checkCheckedButton(targetSelector, sourceSelector);
      };

      // Bind a delegated handler immediately (not inside ready()): a click that
      // lands between script evaluation and the ready callback would otherwise
      // find no handler registered and leave the button state stale.
      $(document).on('click change', sourceSelector, check);

      // Re-check on bfcache restore (e.g. browser back button), where the
      // browser may refill form fields after ready has already run, racing
      // with jQuery-UJS's own disabling of the submit button.
      window.addEventListener('pageshow', function(event) {
        if (event.persisted) { return check(); }
      });

      // Evaluate the initial state once the checkbox exists.
      return $(document).ready(check);
    },

    focusOnFirstErrorItem() {
      return $(document).ready(() => {
        const firstErrorItem = document.querySelector('.has-error');
        return firstErrorItem && firstErrorItem.focus();
      });
    },

    syntaxHighlight(code) {
      let json = typeof code !== 'string' ? JSON.stringify(code, undefined, 2) : code;

      json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

      return json.replace(
        /("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g,
        function(match) {
          let cls = 'number';
          if (/^"/.test(match)) {
            if (/:$/.test(match)) {
              cls = 'key';
            } else {
              cls = 'string';
            }
          } else if (/true|false/.test(match)) {
            cls = 'boolean';
          } else if (/null/.test(match)) {
            cls = 'null';
          }

          return '<span class="' + cls + '">' + match + '</span>';
      });
    }
  };
})();

this.NewflowUi = NewflowUi;
}).call(this);
