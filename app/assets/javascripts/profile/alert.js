(function() {
  OX.Alert = {
  displayInsideElement: function(element) {
  return function(options) {
  return OX.alert.display(_.extend(options, {
    parentEl: element
  }));
};
},
display: function(options) {
  var alert, icon, parent, type;
parent = $(options.parentEl || '#application-body');
alert = parent.find('.alert');
icon = options.icon || 'exclamation-sign';
type = options.type || 'danger';
if (!alert.length) {
  parent.prepend("<div class=\"ox-alert fade in alert alert-" + type + " alert-dismissible\" role=\"alert\">\n  <span class=\"glyphicon glyphicon-" + icon + "\" aria-hidden=\"true\"></span>\n  <span class=\"msg\"></span>\n  <button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"" + OX.I18n.alert.close + "\">\n    &times;\n </button>\n</div>");
  alert = parent.find('.alert');
}
alert.show().find(".msg").text(_.isObject(options) ? options.message || options.statusText: options);
if (options.hideAfter || options.type === 'success') {
  _.delay(function() {
  return alert.alert('close');
}, options.hideAfter || 15000);
}
return alert;
}
};

}).call(this);
