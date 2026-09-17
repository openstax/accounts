// x-editable type wrapping the shared school autocomplete
// (newflow/school_autocomplete.js) for the profile page's school row.
(function() {
  'use strict';

  function ProfileSchool(options) {
    // `tpl` is a function so OX.Profile.School's strings are read at
    // construction, not at parse time -- same deferral as OX.Profile.Name.
    var defaults = $.extend({}, ProfileSchool.defaults, { tpl: ProfileSchool.defaults.tpl() });
    this.init('profile_school', options, defaults);
  }

  ProfileSchool.defaults = $.extend({}, $.fn.editabletypes.abstractinput.defaults, {
    tpl: function() {
      // The label contains literal double quotes, which would close the
      // attribute early.
      var label = OX.Profile.School.useAsEnteredLabel.replace(/"/g, '&quot;');
      // The visible "Self-reported school" label lives in a div outside this
      // generated form, so the input needs its own accessible name.
      return '<div class="school-autocomplete" data-use-as-entered-label="' + label + '"' +
        ' data-endpoint="' + OX.Profile.School.schoolsPath + '">' +
        '<input type="text" name="school_name" aria-label="self-reported school" ' +
        'class="form-control input-sm" placeholder="' + OX.Profile.School.placeholder + '">' +
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
    schoolsPath: '/i/schools',

    editable: function(el, attribs) {
      el.editable({
        value: attribs,
        success: function(response) {
          $(this).find('.text-content')
            .text(response.self_reported_school || OX.Profile.School.blankPrompt);
        }
      });
    }
  };
})();
