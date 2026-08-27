(function() {
OX.Signin.Login = class Login {

  static initialize() {
    const card = $('.ox-card.login');
    if (card.length) { return new OX.Signin.Login(card); }
  }

  constructor(el) {
    this.onHelpClick = this.onHelpClick.bind(this);
    this.el = el;
    this.el.find('a.trouble').click(this.onHelpClick);
  }

  onHelpClick(ev) {
    ev.preventDefault();
    return this.el.find('.login-help').slideToggle('fast');
  }
};
}).call(this);
