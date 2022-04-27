$(document).ready(function() {
  // OX_BOOTSTRAP_INFO is set by

  OxAccount.parentLocation = window.OX_BOOTSTRAP_INFO != null ?
    window.OX_BOOTSTRAP_INFO.parentLocation : undefined;
  OxAccount.proxy = new Porthole.WindowProxy(OxAccount.parentLocation);
  // Register an event handler to receive messages
  OxAccount.proxy.addEventListener(
    msg => (() => {
      const result = [];
      for (let name in msg.data) {
        const args = msg.data[name];
        result.push((typeof OxAccount.Api[name] === 'function' ? OxAccount.Api[name](args) : undefined));
      }
      return result;
    })()
  );

  return OxAccount.proxy.post({iFrameReady: true});
});
