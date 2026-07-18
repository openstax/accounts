(function() {
const IS_EDU = new RegExp('\.edu\s*$', 'i');

NewflowUi.SignupEmailValidations = class SignupEmailValidations {

  constructor() {
    _.bindAll(this, 'onChange', 'onSubmit');
    this.group = $('.email-input-group.newflow');
    this.email = this.group.find('.myschool_email').show();
    this.email.change(this.onChange);
    this.group.closest('form').submit(this.onSubmit);
    this.userType = 'instructor';
    Mailcheck.defaultTopLevelDomains.concat(['pl']); // extend TLDs for our Polish users
  }

  onChange() {
    if (this.showing_warning) {
      return this.clearWarnings();
    }
  }

  onSubmit(ev) {
    if (!((this.email.val() === '') || this.showing_warning || IS_EDU.test(this.email.val()))) {
      if (this.userType === 'instructor') {
        this.showing_warning = true;
        this.group.addClass('has-error');
        this.group.find(".errors").empty();
        this.group.find(".edu.warning").show();
        this.email.focus();
        ev.preventDefault();
        return window.setTimeout(( function() {
          if ($('#signup_terms_accepted').is(':checked')) {
            return $('#signup_form_submit_button').prop('disabled', false);
          }
        }), 100);
      } else {
        return $("#signup_email").mailcheck({
          suggested: (element, suggestion) => {
            this.showing_warning = true;
            this.group.addClass('has-error');
            this.group.find(".errors").empty();
            this.group.find("#suggestion").text(suggestion.domain);
            this.group.find(".mistype.warning").show();
            $('#signup_email').focus();
            return ev.preventDefault();
          },

          empty(element) {
            return $(".mistype.warning").hide();
          }
        });
      }
    }
  }

  clearWarnings() {
    this.group.removeClass('has-error');
    this.group.find(".edu.warning").hide();
    this.group.find(".mistype.warning").hide();
    this.showing_warning = false;
    return this.checkCheckedButton('#signup_form_submit_button', '#signup_terms_accepted');
  }

  checkCheckedButton(targetSelector, sourceSelector) {
    if ($(sourceSelector).is(':checked')) {
      return this.enableButton(targetSelector);
    } else {
      return this.disableButton(targetSelector);
    }
  }
};
}).call(this);
