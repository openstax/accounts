(function() {
OX.Signup.TypeSelector = class TypeSelector {

  static initialize() {
    const role = $('#signup_role');
    if (role.length) { return this.type_selector = new TypeSelector(role); }
  }

  constructor(el) {
    this.el = el;
    _.bindAll(this, 'onChange');
    $("input[type='submit']").attr('disabled', true);
    this.el.change(this.onChange);
    if (this.el.val()) { this.onChange(); }
  }

  onChange() {
    $("input[type='submit']").attr('disabled', false);
    return this.getEmail().setType(this.el.val());
  }

  getEmail() {
    return this._email || (this._email = new OX.Signup.EmailValue());
  }
};
}).call(this);
