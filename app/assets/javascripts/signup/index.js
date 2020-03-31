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
  if ( input !== null ) {
    window.intlTelInput(input, {
      formatOnInit: true,
      utilsScript: "libphonenumber/utils.js",
      separateDialCode: true,
      preferredCountries: ['us', 'pl']
    });
  }
});
