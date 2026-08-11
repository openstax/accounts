(function() {
OX.ConfirmationPopover = class ConfirmationPopover {

  constructor(options) {
    this.options = _.defaults({}, options, {
      html: true,
      placement: 'right',
      message: ''
    }, OX.I18n.confirmation_popover);
    // call after defaults are set since generateContent reads @options
    this.options.content = $(this.generateContent());
    const popover = $(this.options.target).popover(this.options);
    popover.popover('show');
    this.options.content.on('click', '.btn', function(ev) {
      popover.popover('destroy');
      const isAbort = $(this).hasClass('confirm-dialog-btn-abort');
      const cb = isAbort ? options.onCancel : options.onConfirm;
      if (cb) { return cb(ev); }
    });
  }

  generateContent() {
    return `\
<div>
  <span class="message">${this.options.message}</span>
  <p class="button-group" style="margin-top: 10px; text-align: center;">
    <button type="button" class="btn btn-small confirm-dialog-btn-abort">${this.options.cancelText}</button>
    <button type="button" class="btn btn-small btn-danger confirm-dialog-btn-confirm">${this.options.confirmText}</button>
  </p>
</div>\
`;
  }
};
}).call(this);
