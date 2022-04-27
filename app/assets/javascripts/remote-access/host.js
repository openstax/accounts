// Methods defined here are internal and trusted
// They are not intended to be callable directly by iframe postMessage
OxAccount.Host = {
  onPageLoad(page) {
    OxAccount.proxy.post({pageLoad: page});
  },

  loginComplete(back) {
    this.setUrl(back);
  },

  setUrl(url) {
    $('#content').attr({src: url});
  }
};
