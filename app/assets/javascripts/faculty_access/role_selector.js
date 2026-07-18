(function() {
OX.FacultyAccess.RoleSelector = class RoleSelector {

  static initialize() {
    const role = $('#apply_role');
    if (role.length) { return this.role_selector = new RoleSelector(role); }
  }

  constructor(el) {
    this.el = el;
    _.bindAll(this, 'onChange');
    this.el.change(this.onChange);

    if (this.el.val()) {
      $('#role-dependent-fields').show(); // avoid slideDown if role set on load
      this.onChange();
    }
  }


  onChange() {
    if (this.el.val() === "instructor") {
      $('[data-only="instructor"]').parent().show();
      $('[data-except="instructor"]').parent().hide();
    } else {
      $('[data-only="instructor"]').parent().hide();
      $('[data-except="instructor"]').parent().show();
    }

    return $('#role-dependent-fields').slideDown();
  }
};
}).call(this);
