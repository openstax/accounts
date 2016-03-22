//= require bootstrap-editable
//= require ../vendor/underscore
//= require ./namespace
//= require ./name
//= require ./email
//= require_self


$(document).ready(function(){
  $.each(['Name','Email'], function(i, obj){
    if (OX.Profile[obj].initialize){ OX.Profile[obj].initialize(); }
  });
});
