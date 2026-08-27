(function() {
const IS_EDU = /\.edu\s*$/i;

OX.Signup.EmailValue = class EmailValue {

  constructor() {
    _.bindAll(this, 'onChange', 'onSubmit');
    this.group = $('.email-input-group');
    this.email = this.group.find('#signup_email').show();
    this.email.change(this.onChange);
    this.group.closest('form').submit(this.onSubmit);
    this.userType = '';
    if (!Mailcheck.defaultTopLevelDomains.includes('pl')) { Mailcheck.defaultTopLevelDomains.push('pl'); } // extend TLDs for our Polish users
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
        return ev.preventDefault();
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
    return this.showing_warning = false;
  }

  setType(newUserType) {
    newUserType = newUserType === "student" ? "student" : "instructor";
    this.group.find(`[data-audience=\"${this.userType}\"]`).hide();
    this.userType = newUserType;
    return this.group.find(`[data-audience=\"${this.userType}\"]`).show();
  }
};
}).call(this);
