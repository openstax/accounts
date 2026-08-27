(function() {
//#= require_self
//#= require ./login

if (!window.OX) { window.OX = {}; }
if (!window.OX.Signin) { window.OX.Signin = {}; }

$(document).ready( () => (() => {
  const result = [];
  for (var name in OX.Signin) {
    var klass = OX.Signin[name];
    result.push(klass.initialize());
  }
  return result;
})());
}).call(this);
