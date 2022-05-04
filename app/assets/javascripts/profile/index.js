//= require bootstrap-editable
//= require ../vendor/underscore
//= require ./confirmation-popover
//= require ./alert
//= require ./name
//= require ./email
//= require ./authentication
//= require ./namespaces
//= require_self

$(document).ready(function(){
  Accounts.Email.initialize();
  Accounts.Authentication.initialize();
  $('[data-toggle="tooltip"]').tooltip()
});
