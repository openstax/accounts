##= require jquery
##= require_self


window.OxAccount = {

  $: jQuery.noConflict()

}

# setup a tiny pubsub that piggybacks onto jQuery's event system
PUBSUB = jQuery({})
for method in ['on', 'off', 'trigger']
  OxAccount[method] = -> PUBSUB[method].apply(PUBSUB, arguments)

# boot up
OxAccount.$(document).ready ->

  debugger
