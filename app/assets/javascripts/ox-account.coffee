##= require jquery
##= require_self
##= require_tree ./accounts
##= require bootstrap/modal

# setup a tiny pubsub that piggybacks onto jQuery's event system
PUBSUB = jQuery({})

window.OxAccount = {
  $: jQuery
}

forward = (method) ->
  OxAccount[method] = -> PUBSUB[method].apply(PUBSUB, arguments)
forward(method) for method in ['on', 'off', 'trigger']
