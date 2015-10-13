##= require jquery
##= require bootstrap/modal
##= require_self
##= require_tree .

# setup a tiny pubsub that piggybacks onto jQuery's event system
PUBSUB = jQuery({})

# the erb loader script will set this for the external script, but iframe will not
window.OxAccount = (window.OxAccount || {});

window.OxAccount.$ = jQuery;

forward = (method) ->
  OxAccount[method] = -> PUBSUB[method].apply(PUBSUB, arguments)
forward(method) for method in ['on', 'off', 'trigger']
