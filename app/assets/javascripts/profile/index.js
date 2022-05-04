//= require bootstrap-editable
//= require ../vendor/underscore
//= require ./confirmation-popover
//= require ./alert
//= require ./name
//= require ./email
//= require ./authentication
//= require_self

$(document).ready(function(){
  window.Accounts ||= {};
  window.Accounts.Profile ||= {};
  Accounts.Profile.Email.initialize();
  Accounts.Profile.Authentication.initialize();
  $('[data-toggle="tooltip"]').tooltip()
});
