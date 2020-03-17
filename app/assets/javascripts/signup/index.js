//= require ../vendor/underscore
//= require ../vendor/mailcheck
//= require ./namespace
//= require ./type-selector
//= require ./email-value
//= require ./phone-number
//= require_self

$(document).ready(function(){
  $('form:first *:input[type!=hidden]:first').focus();
  OX.Signup.TypeSelector.initialize();
  $('[data-toggle="tooltip"]').tooltip()

  var input = document.querySelector(".int-country-code");
  window.intlTelInput(input, {
    formatOnInit: true,
    separateDialCode: true,
    preferredCountries: ['us', 'pl']
  });
});
