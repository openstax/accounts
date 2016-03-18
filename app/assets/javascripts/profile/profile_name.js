// Modified from /vendor/packages/x-editable/address.js

(function ($) {
  "use strict";

  var ProfileName = function (options) {
    this.init('profile_name', options, ProfileName.defaults);
  };

  $.fn.editableutils.inherit(ProfileName, $.fn.editabletypes.abstractinput);

  $.extend(ProfileName.prototype, {

    render: function() {
      this.$input = this.$tpl.find('input');
    },

    // HTML set in explicit success callback instead
    value2html: function(value, element) {},

    // Internal use only
    value2str: function(value) {
      var str = '';
      if(value) {
        for(var k in value) {
          str = str + k + ':' + value[k] + ';';
        }
      }
      return str;
    },

    // Sets value of input.
    value2input: function(value) {
      if(!value) {
        return;
      }
      this.$input.filter('[name="title"]').val(value.title);
      this.$input.filter('[name="first_name"]').val(value.first_name);
      this.$input.filter('[name="last_name"]').val(value.last_name);
      this.$input.filter('[name="suffix"]').val(value.suffix);
    },

    // Get value of input
    input2value: function() {
      return {
        title: this.$input.filter('[name="title"]').val(),
        first_name: this.$input.filter('[name="first_name"]').val(),
        last_name: this.$input.filter('[name="last_name"]').val(),
        suffix: this.$input.filter('[name="suffix"]').val()
      };
    },

    activate: function() {
      this.$input.filter('[name="first_name"]').focus();
    },

    // Attaches handler to submit form in case of 'showbuttons=false' mode
    autosubmit: function() {
      this.$input.keydown(function (e) {
        if (e.which === 13) {
          $(this).closest('form').submit();
        }
      });
    }
  });

  ProfileName.defaults = $.extend({}, $.fn.editabletypes.abstractinput.defaults, {
    tpl: '<div class="editable-profile-name"><label><span>Title: </span><input type="text" name="title" class="input-small form-control" placeholder="Title"></label></div>'+
         '<div class="editable-profile-name"><label><span>First Name: </span><input type="text" name="first_name" class="input-small"></label></div>'+
         '<div class="editable-profile-name"><label><span>Last Name: </span><input type="text" name="last_name" class="input-mini"></label></div>' +
         '<div class="editable-profile-name"><label><span>Suffix: </span><input type="text" name="suffix" class="input-mini"></label></div>',

    inputclass: ''
  });

  $.fn.editabletypes.profile_name = ProfileName;

}(window.jQuery));
