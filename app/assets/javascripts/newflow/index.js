//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require ../vendor/underscore
//= require ../vendor/mailcheck
//= require ./newflow_ui
//= require ./educator_signup_email_validations
//= require ./educator_complete_dynamic
//= require intlTelInput
//= require multiselect
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

  // Validate name for unallowed chars
  var errorDiv = '<div class="errors invalid-message">Name cannot contain special characters</div>';
  function check_for_specialness(obj) {
      if(/^[a-zA-Z0-9- ]*$/.test(obj.value) == false) {
          $(obj).addClass('has-error');
          $(obj).closest('.control-group').append(errorDiv);
      }else{
          $(obj).removeClass('has-error');
          $(obj).closest('.control-group').remove(errorDiv);
      }
  }
  $("#signup_first_name").blur(function (e) {
      check_for_specialness(this);
  });

    $("#signup_last_name").blur(function (e) {
        check_for_specialness(this);
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
      let country_code = telInput.getSelectedCountryData().dialCode;
      $('#signup_country_code').val(country_code)
      return true;
    }
    form.addEventListener('submit', step1_submit);
  }
});
