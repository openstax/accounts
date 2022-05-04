//= require bootstrap-editable
//= require ../vendor/underscore
//= require ./namespace
//= require ./confirmation-popover
//= require ./alert
//= require ./name
//= require ./email
//= require ./authentication
//= require_self


$(document).ready(function(){
  Accounts.Profile.Email.initialize();
  Accounts.Profile.Authentication.initialize();
  $('[data-toggle="tooltip"]').tooltip()
});
