//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require underscore.js
//= require x-editable-bootstrap.js
//= require knockout.js
//= require ./namespace
//= require ./confirmation-popover
//= require ./alert
//= require ./email
//= require ./authentication
//= require_self


$(document).ready(function(){
  OX.Profile.Email.initialize();
  OX.Profile.Authentication.initialize();
});
