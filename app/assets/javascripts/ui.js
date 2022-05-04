function disableButton(selector) {
  $(selector).attr('disabled', 'disabled');
  $(selector).addClass('ui-state-disabled ui-button-disabled');
  $(selector).attr('aria-disabled', true);
};

function enableButton(selector) {
  $(selector).removeAttr('disabled');
  $(selector).removeAttr('aria-disabled');
  $(selector).removeClass('ui-state-disabled ui-button-disabled');
  $(selector).button();
};

function renderAndOpenDialog(html_id, content, modal_options) {
  if (modal_options == null) { modal_options = {}; }
  if ($('#' + html_id).exists()) { $('#' + html_id).remove(); }
  $("#application-body").append(content);
  $('#' + html_id).modal(modal_options);

  // Code to center the dialog
  const modalDialog = $('#' + html_id + ' .modal-dialog');
  const modalHeight = modalDialog.outerHeight();
  const userScreenHeight = window.outerHeight;

  if (modalHeight > userScreenHeight) {
    modalDialog.css('overflow', 'auto'); //set to overflow if no fit
  } else {
    modalDialog.css('margin-top', //center it if it does fit
                    ((userScreenHeight / 2) - (modalHeight / 2)));
  }
};

function checkCheckedButton(targetSelector, sourceSelector) {
  if ($(sourceSelector).is(':checked')) {
    this.enableButton(targetSelector);
  } else {
    this.disableButton(targetSelector);
  }
};

function enableOnChecked(targetSelector, sourceSelector) {
  return $(document).ready(() => {
    if (!$(sourceSelector).is(':checked')) { this.disableButton(targetSelector); }

    $(sourceSelector).on('click', () => {
      this.checkCheckedButton(targetSelector, sourceSelector);
    });
  });
};

function syntaxHighlight(code)
{
    const json = _.escape(typeof code === !'string' ? JSON.stringify(code, undefined, 2) : code);

    return json.replace(
        /("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g,
        function (match) {
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
};


