OX.Alert = {
  displayInsideElement(element) {
    // Return a function that will display the alert inside the given element
    return options => OX.alert.display(_.extend(options, {parentEl: element}));
  },

  display(options) {
    const parent = $(options.parentEl || '#application-body');
    let alert = parent.find('.alert');
    const icon = options.icon || 'exclamation-sign';
    const type = options.type || 'danger';

    if (!alert.length) {
      parent.prepend(`\
<div class="ox-alert fade in alert alert-${type} alert-dismissible" role="alert">
  <span class="glyphicon glyphicon-${icon}" aria-hidden="true"></span>
  <span class="msg"></span>
  <button type="button" class="close" data-dismiss="alert" aria-label="${OX.I18n.alert.close}">
    &times;
 </button>
</div>\
`);
      alert = parent.find('.alert');
    }

    alert.show().find(".msg").text(
      _.isObject(options) ? (options.message || options.statusText) : options
    );
    if (options.hideAfter || (options.type === 'success')) {
      _.delay(
        () => alert.alert('close'),
        options.hideAfter || 15000  // defaults to 15 seconds
      );
    }
    return alert;
  }
};
