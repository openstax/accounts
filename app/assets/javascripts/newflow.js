// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/
//= require ./application
//= require ./newflow_signup
//= require bootstrap

$(document).ready(function () {
    // Toggle show/hide password field
    $("#password-show-hide-button").click(function (e) {
        $(".toggle-show-hide").toggle();

        var password_field = $('[name$="[password]"]')[0];
        if ($(password_field).attr("type") == "password") {
            $(password_field).attr("type", "text");
            if (typeof gaShowHide === "function")
            {
                gaShowHide('Show');
            }
            
        } else {
            $(password_field).attr("type", "password");
            if (typeof gaShowHide === "function")
            {
                gaShowHide('Hide');
            }
        }
    });
});
