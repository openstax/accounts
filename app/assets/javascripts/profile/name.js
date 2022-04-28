// Based on /vendor/packages/x-editable/address.js

(function() {

  function generateTemplate() {
    return `\
<div><input type="text" name="title" class="form-control input-sm" placeholder="${OX.I18n.name.title}"></div>
<div><input type="text" name="first_name" class="form-control input-sm" placeholder="${OX.I18n.name.first_name}"></div>
<div><input type="text" name="last_name" class="form-control input-sm" placeholder="${OX.I18n.name.last_name}"></div>
<div><input type="text" name="suffix" class="form-control input-sm" placeholder="${OX.I18n.name.suffix}"></div>\
`;
  }

  OX.Profile.Name = class extends $.fn.editabletypes.abstractinput {
    static defaults = {
      ...$.fn.editabletypes.abstractinput.defaults,
      inputClass: '',
      get tpl() {
        return generateTemplate();
      }
    };

    constructor(options) {
      super();
      this.init('profile_name', options, OX.Profile.Name.defaults);
    }

    render() {
      this.$input = this.$tpl.find('input');
    }

    value2html() {}

    value2str(value) {
      let str = '';
      if (value) {
        for (let k in value) {
          str = str + k + ':' + value[k] + ';';
        }
      }
      return str;
    }

    value2input(value) {
      if (!value) { return; }
      this.$input.filter('[name="title"]').val(value.title);
      this.$input.filter('[name="first_name"]').val(value.first_name);
      this.$input.filter('[name="last_name"]').val(value.last_name);
      this.$input.filter('[name="suffix"]').val(value.suffix);
    }

    input2value() {
      return {
        title: this.$input.filter('[name="title"]').val(),
        first_name: this.$input.filter('[name="first_name"]').val(),
        last_name: this.$input.filter('[name="last_name"]').val(),
        suffix: this.$input.filter('[name="suffix"]').val()
      };
    }

    activate() {
      this.$input.filter('[name="first_name"]').focus();
    }

    autosubmit() {
      this.$input.keydown(function(e) {
        if (e.key === 'Enter') { $(this).closest('form').submit(); }
      });
    }
  }

  $.fn.editabletypes.profile_name = OX.Profile.Name;

}).call(this);
