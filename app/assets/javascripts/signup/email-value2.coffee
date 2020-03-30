(function() {
  var IS_EDU;

  IS_EDU = new RegExp('\.edu\s*$', 'i');

  OX.Signup.EmailValue = (function() {
    function EmailValue() {
      _.bindAll(this, 'onChange', 'onSubmit');
      this.group = $('.email-input-group');
      this.email = this.group.find('.signup_email').show();
      this.email.change(this.onChange);
      this.group.closest('form').submit(this.onSubmit);
      this.userType = '';
      Mailcheck.defaultTopLevelDomains.concat(['pl']);
    }

    EmailValue.prototype.onChange = function() {
      if (this.showing_warning) {
        return this.clearWarnings();
      }
    };

    EmailValue.prototype.onSubmit = function(ev) {
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
            suggested: (function(_this) {
              return function(element, suggestion) {
                _this.showing_warning = true;
                _this.group.addClass('has-error');
                _this.group.find(".errors").empty();
                _this.group.find(".edu.warning").show();
                _this.group.find("#suggestion").text(suggestion.domain);
                _this.group.find(".mistype.warning").show();
                $('#signup_email').focus();
                return ev.preventDefault();
              };
            })(this),
            empty: function(element) {
              return $(".mistype.warning").hide();
            }
          });
        }
      }
    };

    EmailValue.prototype.clearWarnings = function() {
      this.group.removeClass('has-error');
      this.group.find(".edu.warning").hide();
      this.group.find(".mistype.warning").hide();
      return this.showing_warning = false;
    };

    EmailValue.prototype.setType = function(newUserType) {
      newUserType = newUserType === "student" ? "student" : "instructor";
      this.group.find("[data-audience=\"" + this.userType + "\"]").hide();
      this.userType = newUserType;
      return this.group.find("[data-audience=\"" + this.userType + "\"]").show();
    };

    return EmailValue;
  })();

}).call(this);
