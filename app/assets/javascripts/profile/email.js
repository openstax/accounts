// The forms in this control are written with x-editable styling so that it looks
// similar to the other controls.

// Converted by pulling from the browser after transpilation.
// Online transpilers made nicer code, but it wasn't correct.
(function() {
  var BASE_URL, Email,
    slice = [].slice;

  BASE_URL = OX.url_prefix + "/contact_infos";

  Email = (function() {
    function Email(el1) {
      this.el = el1;
      _.bindAll.apply(_, [this].concat(slice.call(_.functions(this))));
      this.$el = $(this.el);
      this.id = this.$el.attr('data-id');
      this.$el.find('.searchable').change(this.saveSearchable);
      this.$el.find('.resend-confirmation').click(this.sendVerification);
      this.$el.find('.email, .unconfirmed-warning').click(this.toggleProperties);
      this.update();
    }

    Email.prototype.update = function() {
      var delBtn;
      delBtn = this.$el.find('.delete');
      delBtn.off('click', this.confirmDelete);
      if (this.isOnlyVerifiedEmail()) {
        return delBtn.hide();
      } else {
        return delBtn.on('click', this.confirmDelete);
      }
    };

    Email.prototype.toggleProperties = function() {
      return this.$el.toggleClass('expanded');
    };

    Email.prototype.toggleSpinner = function(show) {
      return this.$el.find('.spinner').toggle(_.isBoolean(show) && show);
    };

    Email.prototype.url = function(action) {
      return (BASE_URL + "/" + this.id) + (action ? "/" + action : '');
    };

    Email.prototype.sendVerification = function(ev) {
      ev.preventDefault();
      ev.target.disabled = true;
      return $.ajax({
        type: "PUT",
        url: this.url('resend_confirmation')
      }).success((function(_this) {
        return function(resp) {
          return OX.Alert.display({
            message: resp.message,
            type: 'success',
            parentEl: _this.$el
          });
        };
      })(this)).error((function(_this) {
        return function(e) {
          OX.Alert.display(_.extend(e, {
            parentEl: _this.$el
          }));
          return ev.target.disabled = false;
        };
      })(this));
    };

    Email.prototype.saveSearchable = function(ev) {
      var data;
      this.toggleSpinner(true);
      ev.target.disabled = true;
      data = {
        is_searchable: ev.target.checked
      };
      return $.ajax({
        type: "PUT",
        url: this.url('set_searchable'),
        data: data
      }).success((function(_this) {
        return function(resp) {
          return _this.set(resp);
        };
      })(this)).error((function(_this) {
        return function(e) {
          ev.target.checked = !ev.target.checked;
          return OX.Alert.display(_.extend(e, {
            parentEl: _this.$el
          }));
        };
      })(this)).complete((function(_this) {
        return function() {
          ev.target.disabled = false;
          return _this.toggleSpinner(false);
        };
      })(this));
    };

    Email.prototype.set = function(contact) {
      if (contact.id != null) {
        this.id = contact.id;
        this.$el.attr('data-id', contact.id);
      }
      if (contact.is_searchable != null) {
        return this.$el.find('.searchable').prop('checked', contact.is_searchable);
      }
    };

    Email.prototype.isOnlyVerifiedEmail = function() {
      return this.$el.hasClass('verified') && !this.$el.siblings('.email-entry.verified').length;
    };

    Email.prototype.confirmDelete = function(ev) {
      return OX.showConfirmationPopover({
        title: '',
        message: OX.I18n.email.confirm_delete,
        target: ev.target,
        placement: 'top',
        onConfirm: this["delete"]
      });
    };

    Email.prototype["delete"] = function() {
      this.toggleSpinner(true);
      return $.ajax({
        type: "DELETE",
        url: this.url()
      }).success((function(_this) {
        return function() {
          _this.$el.remove();
          return OX.Profile.Email.onDeleteEmail(_this);
        };
      })(this)).error(OX.Alert.displayInsideElement(this.$el)).complete(this.toggleSpinner);
    };

    return Email;

  })();

  OX.Profile.Email = {
    initialize: function() {
      $('.email-entry').each(function(indx, el) {
        return $(el).data({
          email: new Email(this)
        });
      });
      return this.addEmail = $('#add-an-email').click((function(_this) {
        return function() {
          return _this.onAddEmail();
        };
      })(this));
    },
    onDeleteEmail: function() {
      return $('.info .email-entry').each(function(indx, el) {
        return $(el).data().email.update();
      });
    },
    onAddEmail: function() {
      var email, input;
      email = $('#email-template').children().clone().addClass('new');
      input = $(email).insertBefore(this.addEmail).find('.email .value');
      this.addEmail.hide();
      input.editable({
        url: BASE_URL,
        params: function(params) {
          return {
            'contact_info[type]': 'EmailAddress',
            'contact_info[value]': params.value
          };
        },
        ajaxOptions: {
          type: 'POST'
        }
      }).on('hidden', (function(_this) {
        return function(e, reason) {
          _this.addEmail.show();
          if (reason !== 'save') {
            return email.remove();
          }
        };
      })(this)).on('save', function(e, params) {
        email.removeClass('new');
        _.defer(function() {
          input.editable('destroy');
          return input.text(params.response.contact_info.value);
        });
        email = new Email(email);
        return email.set(params.response.contact_info);
      });
      return _.defer(function() {
        return input.editable('show');
      });
    }
  };

}).call(this);
