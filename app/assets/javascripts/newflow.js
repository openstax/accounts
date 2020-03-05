// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/
//= require ./application
//= require ./signup
//= require jquery
//= require jquery_ujs
//= require bootstrap

$(document).ready(function () {
    // Toggle show/hide password field
    $("#password-show-hide-button").click(function (e) {
        $(".toggle-show-hide").toggle();

        var password_field = $('[name$="[password]"]')[0];
        if ($(password_field).attr("type") == "password") {
            $(password_field).attr("type", "text");
            gaShowHide('Show');
        } else {
            $(password_field).attr("type", "password");
            gaShowHide('Hide');
        }
    });
});
