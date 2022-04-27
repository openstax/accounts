// Methods defined here are executed in the accounts side of the iframe
// in response to a message sent from a trusted host who's iframing the page
OxAccount.Api = {

  displayProfile() {
    OxAccount.Host.setUrl("/profile");
  },

  displayLogin(url) {
    OxAccount.Host.setUrl(`/remote/start_login?start=${url}`);
  },

  displayLogout(url) {
    OxAccount.Host.setUrl(`/remote/start_logout?start=${url}`);
  },

  // onLogin is actually called by our login completion handler,
  // we just forward data onto listening parent
  onLogin(data) {
    OxAccount.proxy.post({onLogin: data});
  }

};
