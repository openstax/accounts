//= require bootstrap-editable
//= require ../vendor/underscore
//= require ../newflow/school_autocomplete
//= require ./namespace
//= require ./editable_error
//= require ../confirmation-popover
//= require ../alert
//= require ./name
//= require ./school
//= require ./email
//= require ./authentication
//= require_self


$(document).ready(function(){
  $.each(['Name','Email', 'Authentication'], function(i, obj){
    if (OX.Profile[obj].initialize){ OX.Profile[obj].initialize(); }
  });
  $('[data-toggle="tooltip"]').tooltip()
});

// x-editable's save and cancel buttons are icon-only; give them names.
$(document).on('shown', '.editable', function(e, editable) {
  var $form = editable && editable.container && editable.container.$form;
  if (!$form) { return; }
  $form.find('.editable-submit').attr('aria-label', 'Save');
  $form.find('.editable-cancel').attr('aria-label', 'Cancel');
});
