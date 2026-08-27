(function() {
// Modified from /vendor/packages/x-editable/address.js

// NOTE: this is a plain constructor function, not an ES6 `class` — deliberately.
// $.fn.editableutils.inherit() below (bootstrap-editable) reassigns
// OX.Profile.Name.prototype directly, which throws on a real `class` (whose
// `.prototype` is non-writable). CoffeeScript's compiler always emitted plain
// functions for `class`, which is what this legacy prototype-mutation interop
// depends on.
function Name(options) {
  // We defer evaluating template until construction, as otherwise it would try
  // to read values if OX.I18n before its initialisation.
  let {
    defaults
  } = OX.Profile.Name;
  defaults = $.extend(defaults, {
    tpl: defaults.tpl(),
  });
  this.init('profile_name', options, OX.Profile.Name.defaults);
}

Name.initClass = function() {
  this.defaults = $.extend({}, $.fn.editabletypes.abstractinput.defaults, {
    tpl() { return `\
<div><input type="text" name="title" class="form-control input-sm" placeholder="${OX.I18n.name.title}"></div>
<div><input type="text" name="first_name" aria-label="first name (required)" required class="form-control input-sm" placeholder="${OX.I18n.name.first_name}"></div>
<div><input type="text" name="last_name" aria-label="last name (required)" required class="form-control input-sm" placeholder="${OX.I18n.name.last_name}"></div>
<div><input type="text" name="suffix" class="form-control input-sm" placeholder="${OX.I18n.name.suffix}"></div>\
`; },
    inputclass: ''
  }

  );
};

Name.editable = function(el, attribs) {
  return el.editable({
    value: attribs,
    success(response) { return $(this).find('.text-content').html(response.full_name); },
    validate(attrs) {
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

OX.Profile.Name = Name;
Name.initClass();


$.fn.editabletypes.profile_name = OX.Profile.Name;
$.fn.editableutils.inherit(OX.Profile.Name, $.fn.editabletypes.abstractinput);
$.extend(OX.Profile.Name.prototype, {
  render() {
    return this.$input = this.$tpl.find('input');
  },

  value2html() {},

  value2str(value) {
    let str = '';
    if (value) {
      for (var k in value) {
        str = str + k + ':' + value[k] + ';';
      }
    }
    return str;
  },

  value2input(value) {
    if (!value) { return; }
    this.$input.filter('[name="title"]').val(value.title);
    this.$input.filter('[name="first_name"]').val(value.first_name);
    this.$input.filter('[name="last_name"]').val(value.last_name);
    return this.$input.filter('[name="suffix"]').val(value.suffix);
  },

  input2value() {
    return {
      title: this.$input.filter('[name="title"]').val(),
      first_name: this.$input.filter('[name="first_name"]').val(),
      last_name: this.$input.filter('[name="last_name"]').val(),
      suffix: this.$input.filter('[name="suffix"]').val()
    };
  },

  activate() {
    return this.$input.filter('[name="first_name"]').focus();
  },

  autosubmit() {
    return this.$input.keydown(function(e) {
      if (e.which === 13) { return $(this).closest('form').submit(); }
    });
  }

});
}).call(this);
