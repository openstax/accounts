//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require ../vendor/underscore
//= require ../vendor/mailcheck
//= require ./newflow_ui
//= require ./educator_signup_email_validations
//= require intlTelInput
//= require libphonenumber/utils
//= require ./phone-number
//= require_self

$(document).ready(function(){
  $('form:first *:input[type!=hidden]:first').focus();

  $('[data-toggle="tooltip"]').tooltip()

  // Toggle show/hide password field
  $("#password-show-hide-button").click(function (e) {
    $(".toggle-show-hide").toggle();

    var password_field = $('[name$="[password]"]')[0];
    if ($(password_field).attr("type") == "password") {
      $(password_field).attr("type", "text");
      if (typeof gaShowHide === "function") {
        gaShowHide('Show');
      }

    } else {
      $(password_field).attr("type", "password");
      if (typeof gaShowHide === "function") {
        gaShowHide('Hide');
      }
    }
  });

  // Validate phone number
  let input = document.querySelector(".int-country-code");
  if ( input !== null ) {
    let form = input.closest('form');
    let telInput = intlTelInput(input, {
      formatOnInit: true,
      preferredCountries: ['us', 'pl']
    });

    function step1_submit(event) {
      let phone_num = telInput.getNumber();
      $(".int-country-code").val(phone_num);
      return true;
    }
    form.addEventListener('submit', step1_submit);
  }
});
