jQuery.fn.exists = function(){return jQuery(this).length>0;}

jQuery.fn.centerVertically = function() {
  return $(this).css({
    top: '50%',
    'margin-top': function () { return -($(this).height() / 2); }
  });
}

jQuery.fn.centerHorizontally = function() {
  return $(this).css({
    left: '50%',
    'margin-left': function () { return -($(this).width() / 2); }
  });
}

jQuery.fn.center = function() {
  $(this).centerHorizontally();
  $(this).centerVertically();
}