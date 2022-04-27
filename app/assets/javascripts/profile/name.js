// Modified from /vendor/packages/x-editable/address.js
// Then transpiled via the browser

(function() {
  OX.Profile.Name = (function() {

    Name.editable = function(el, attribs) {
      return el.editable({
        value: attribs,
        success: function(response) {
          return $(this).html(response.full_name);
        },
        validate: function(attrs) {
          if (!attrs.first_name && !attrs.last_name) {
            return OX.I18n.name.first_last_name_blank;
          } else if (!attrs.first_name) {
            return OX.I18n.name.first_name_blank;
          } else if (!attrs.last_name) {
            return OX.I18n.name.last_name_blank;
          }
        }
      });
    };

    Name.defaults = $.extend({}, $.fn.editabletypes.abstractinput.defaults, {
      tpl: function() {
        return "<div><input type=\"text\" name=\"title\" class=\"form-control input-sm\" placeholder=\"" + OX.I18n.name.title + "\"></div>\n<div><input type=\"text\" name=\"first_name\" class=\"form-control input-sm\" placeholder=\"" + OX.I18n.name.first_name + "\"></div>\n<div><input type=\"text\" name=\"last_name\" class=\"form-control input-sm\" placeholder=\"" + OX.I18n.name.last_name + "\"></div>\n<div><input type=\"text\" name=\"suffix\" class=\"form-control input-sm\" placeholder=\"" + OX.I18n.name.suffix + "\"></div>";
      },
      inputclass: ''
    });

    function Name(options) {
      var defaults;
      defaults = OX.Profile.Name.defaults;
      defaults = $.extend(defaults, {
        tpl: defaults.tpl()
      });
      this.init('profile_name', options, OX.Profile.Name.defaults);
    }

    return Name;

  })();

  $.fn.editabletypes.profile_name = OX.Profile.Name;

  $.fn.editableutils.inherit(OX.Profile.Name, $.fn.editabletypes.abstractinput);

  $.extend(OX.Profile.Name.prototype, {
    render: function() {
      return this.$input = this.$tpl.find('input');
    },
    value2html: function() {},
    value2str: function(value) {
      var k, str;
      str = '';
      if (value) {
        for (k in value) {
          str = str + k + ':' + value[k] + ';';
        }
      }
      return str;
    },
    value2input: function(value) {
      if (!value) {
        return;
      }
      this.$input.filter('[name="title"]').val(value.title);
      this.$input.filter('[name="first_name"]').val(value.first_name);
      this.$input.filter('[name="last_name"]').val(value.last_name);
      return this.$input.filter('[name="suffix"]').val(value.suffix);
    },
    input2value: function() {
      return {
        title: this.$input.filter('[name="title"]').val(),
        first_name: this.$input.filter('[name="first_name"]').val(),
        last_name: this.$input.filter('[name="last_name"]').val(),
        suffix: this.$input.filter('[name="suffix"]').val()
      };
    },
    activate: function() {
      return this.$input.filter('[name="first_name"]').focus();
    },
    autosubmit: function() {
      return this.$input.keydown(function(e) {
        if (e.which === 13) {
          return $(this).closest('form').submit();
        }
      });
    }
  });

}).call(this);
