//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require underscore
//= require x-editable-bootstrap
//= require knockout
//= require ./namespace
//= require ./name
//= require ./confirmation-popover
//= require ./alert
//= require ./email
//= require ./authentication
//= require_self

$(document).ready(function(){
  OX.Profile.Email.initialize();
  OX.Profile.Authentication.initialize();
});
