//= require bootstrap-editable
//= require ../vendor/underscore
//= require ./namespace
//= require ../confirmation-popover
//= require ../alert
//= require ./name
//= require ./email
//= require ./authentication
//= require_self


$(document).ready(function(){
  $.each(['Name','Email', 'Authentication'], function(i, obj){
    if (OX.Profile[obj].initialize){ OX.Profile[obj].initialize(); }
  });
  $('[data-toggle="tooltip"]').tooltip()
});
