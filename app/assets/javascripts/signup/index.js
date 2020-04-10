//= require ../vendor/underscore
//= require ../vendor/mailcheck
//= require ./namespace
//= require ./type-selector
//= require ./email-value
//= require_self

$(document).ready(function(){
  $('form:first *:input[type!=hidden]:first').focus();
  OX.Signup.TypeSelector.initialize();
  // $('[data-toggle="tooltip"]').tooltip()
});
