//= require ../vendor/underscore
//= require ./namespace
//= require ./confirmation-popover
//= require ./alert
//= require ./name
//= require ./email
//= require ./authentication
//= require_self


$(document).ready(function(){
  OX.Profile.Email.initialize();
  OX.Profile.Authentication.initialize();
  $('[data-toggle="tooltip"]').tooltip()
});
