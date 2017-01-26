##= require_self
##= require ./login

window.OX ||= {}
window.OX.Signin ||= {}

$(document).ready( ->
  klass.initialize() for name, klass of OX.Signin
)
