// Converted from CoffeeScript by pulling from the browser after transpilation
// Online transpilers did not work correctly.

(function() {
  var AuthenticationOption, BASE_URL, Password, SPECIAL_TYPES,
    slice = [].slice,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  BASE_URL = "" + OX.url_prefix;

  AuthenticationOption = (function() {
    function AuthenticationOption(el1) {
      this.el = el1;
      _.bindAll.apply(_, [this].concat(slice.call(_.functions(this))));
      this.$el = $(this.el);
      this.$el.find('.delete').click(this.confirmDelete);
      this.$el.find('.add').click(this.doAdd);
    }

    AuthenticationOption.prototype.confirmDelete = function(ev) {
      return OX.showConfirmationPopover({
        title: '',
        message: OX.I18n.authentication.confirm_delete,
        target: ev.target,
        placement: 'top',
        onConfirm: this.doDelete
      });
    };

    AuthenticationOption.prototype.getType = function() {
      return this.$el.data('provider');
    };

    AuthenticationOption.prototype.doDelete = function() {
      return $.ajax({
        type: "DELETE",
        url: BASE_URL + "/auth/" + (this.getType())
      }).success(this.handleDelete).error(OX.Alert.display);
    };

    AuthenticationOption.prototype.isEnabled = function() {
      return this.$el.closest('.enabled-providers').length !== 0;
    };

    AuthenticationOption.prototype.moveToEnabledSection = function() {
      return this.$el.hide('fast', (function(_this) {
        return function() {
          $('.enabled-providers .providers').append(_this.$el);
          return _this.$el.show();
        };
      })(this));
    };

    AuthenticationOption.prototype.moveToDisabledSection = function() {
      return this.$el.hide('fast', (function(_this) {
        return function() {
          $('.other-sign-in .providers').append(_this.$el);
          return _this.$el.show();
        };
      })(this));
    };

    AuthenticationOption.prototype.doAdd = function() {
      return window.location.href = BASE_URL + "/auth/" + (this.getType());
    };

    AuthenticationOption.prototype.handleDelete = function(response) {
      if (response.location != null) {
        return window.location.href = response.location;
      } else {
        return this.moveToDisabledSection();
      }
    };

    return AuthenticationOption;

  })();

  Password = (function(superClass) {
    extend(Password, superClass);

    function Password(el1) {
      this.el = el1;
      Password.__super__.constructor.apply(this, arguments);
      this.$el.find('.edit').click(this.editPassword);
      this.$el.find('.add').click(this.addPassword);
    }

    Password.prototype.editPassword = function() {
      return window.location.href = BASE_URL + "/change_password_form";
    };

    Password.prototype.addPassword = function() {
      return window.location.href = BASE_URL + "/change_password_form";
    };

    return Password;

  })(AuthenticationOption);

  SPECIAL_TYPES = {
    identity: Password
  };

  OX.Profile.Authentication = {
    initialize: function() {
      $('.authentication').each(function(i, el) {
        var klass;
        klass = SPECIAL_TYPES[$(el).data('provider')] || AuthenticationOption;
        return new klass(el);
      });
      return $('#enable-other-sign-in').click(function(e) {
        e.preventDefault();
        $(this).hide();
        return $('.other-sign-in').slideToggle();
      });
    }
  };

}).call(this);
