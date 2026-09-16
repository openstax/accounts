// x-editable type for the profile page's "Self-reported school" row. Wraps the
// shared school autocomplete combobox (app/assets/javascripts/newflow/school_autocomplete.js)
// so picking a suggestion or typing free text both save through the same
// {school_name, school_id} pair the routine expects.
(function() {
  'use strict';

  function ProfileSchool(options) {
    // Deferred like OX.Profile.Name: `tpl` is a function so OX.I18n.school is
    // read at construction time, after application.html.erb has set it, not
    // when this file is parsed.
    var defaults = $.extend({}, ProfileSchool.defaults, { tpl: ProfileSchool.defaults.tpl() });
    this.init('profile_school', options, defaults);
  }

  ProfileSchool.defaults = $.extend({}, $.fn.editabletypes.abstractinput.defaults, {
    tpl: function() {
      // The label carries literal double quotes (`Use "{school}"`), which
      // would otherwise close the data attribute early.
      var label = OX.I18n.school.use_as_entered_label.replace(/"/g, '&quot;');
      return '<div class="school-autocomplete" data-use-as-entered-label="' + label + '">' +
        '<input type="text" name="school_name" class="form-control input-sm" ' +
        'placeholder="' + OX.I18n.school.placeholder + '">' +
        '<input type="hidden" name="school_id">' +
        '</div>';
    },
    inputclass: ''
  });

  $.fn.editabletypes.profile_school = ProfileSchool;
  $.fn.editableutils.inherit(ProfileSchool, $.fn.editabletypes.abstractinput);

  $.extend(ProfileSchool.prototype, {
    render: function() {
      this.$input = this.$tpl.find('input');
      OxSchoolAutocomplete.attach(this.$tpl.get(0));
    },

    value2html: function() {},

    value2str: function(value) {
      return value ? value.school_name + ';' + value.school_id : '';
    },

    value2input: function(value) {
      if (!value) { return; }
      this.$input.filter('[name="school_name"]').val(value.school_name);
      this.$input.filter('[name="school_id"]').val(value.school_id);
    },

    input2value: function() {
      return {
        school_name: this.$input.filter('[name="school_name"]').val(),
        school_id: this.$input.filter('[name="school_id"]').val()
      };
    },

    activate: function() {
      this.$input.filter('[name="school_name"]').focus();
    }
  });

  window.OX = window.OX || {};
  window.OX.Profile = window.OX.Profile || {};
  window.OX.Profile.School = {
    editable: function(el, attribs) {
      el.editable({
        value: attribs,
        success: function(response) {
          $(this).find('.text-content')
            .text(response.self_reported_school || OX.I18n.school.blank_prompt);
        }
      });
    }
  };
})();
