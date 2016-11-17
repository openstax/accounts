//= require ../vendor/underscore
//= require ./namespace
//= require ./type-selector
//= require ./email-value
//= require_self

$(document).ready(function(){
  OX.Signup.TypeSelector.initialize();
  $('[data-toggle="tooltip"]').tooltip()
});
