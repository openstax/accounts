(function() {
// Methods defined here are internal and trusted
// They are not intended to be callable directly by iframe postMessage
OxAccount.Host = {
  onPageLoad(page) {
    return OxAccount.proxy.post({pageLoad: page});
  },

  loginComplete(back) {
    return this.setUrl(back);
  },

  setUrl(url) {
    return $('#content').attr({src: url});
  }

};
}).call(this);
