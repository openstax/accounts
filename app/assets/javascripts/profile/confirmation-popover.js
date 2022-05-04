(function() {
  function generateContent (options) {
    return `
      <div>
        <span class="message">${options.message}</span>
        <p class="button-group" style="margin-top: 10px; text-align: center;">
          <button type="button" class="btn btn-small confirm-dialog-btn-abort">${options.cancelText}</button>
          <button type="button" class="btn btn-small btn-danger confirm-dialog-btn-confirm">${options.confirmText}</button>
        </p>
      </div>
    `
  };

  Accounts.showConfirmationPopover = function(optionArgs) {
    const options = _.defaults({}, optionArgs, {
      html: true,
      placement: 'right',
      message: ''
    }, OX.I18n.confirmation_popover);

    options.content = $(generateContent(options));

    const popover = $(options.target).popover(options);

    popover.popover('show');

    return options.content.on('click', '.btn', function(ev) {
      var cb, isAbort;
      popover.popover('destroy');
      isAbort = $(this).hasClass('confirm-dialog-btn-abort');
      cb = isAbort ? optionArgs.onCancel : optionArgs.onConfirm;
      if (cb) {
        return cb(ev);
      }
    });
  };

}).call(this);
