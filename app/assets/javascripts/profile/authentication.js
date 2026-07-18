(function() {
const BASE_URL = `${OX.url_prefix}`;

// _.functions(obj) (underscore) only finds *enumerable* function properties.
// CoffeeScript's `class` compiled to a plain object-literal prototype (always
// enumerable), which is what `_.bindAll(@, _.functions(@)...)` relied on to
// bind every method. ES6 `class` methods are non-enumerable, so this walks
// the prototype chain directly to preserve "bind every method" behavior.
function allMethodNames(obj) {
  const names = [];
  for (let proto = Object.getPrototypeOf(obj); proto && proto !== Object.prototype; proto = Object.getPrototypeOf(proto)) {
    for (const name of Object.getOwnPropertyNames(proto)) {
      if (name !== 'constructor' && typeof proto[name] === 'function' && !names.includes(name)) { names.push(name); }
    }
  }
  return names;
}

class AuthenticationOption {

  constructor(el) {
    this.el = el;
    _.bindAll(this, ...allMethodNames(this));
    this.$el = $(this.el);
    this.$el.find('.delete').click(this.confirmDelete);
    this.$el.find('.delete--newflow').click(this.confirmDeleteNewflow);
    this.$el.find('.add').click(this.add);
    this.$el.find('.add--newflow').click(this.addNewflow);
  }

  confirmDelete(ev) {
    return new OX.ConfirmationPopover({
      title: '',
      message: OX.I18n.authentication.confirm_delete,
      target: ev.target,
      placement: 'top',
      onConfirm: this.delete
    });
  }

  confirmDeleteNewflow(ev) {
    return new OX.ConfirmationPopover({
      title: '',
      message: OX.I18n.authentication.confirm_delete,
      target: ev.target,
      placement: 'top',
      onConfirm: this.deleteNewflow
    });
  }

  getType() {
    return this.$el.data('provider');
  }

  delete() {
    return $.ajax({type: "DELETE", url: `${BASE_URL}/auth/${this.getType()}`})
      .success( this.handleDelete )
      .error(OX.Alert.display);
  }

  deleteNewflow() {
    return $.ajax({type: "DELETE", url: `${BASE_URL}/i/auth/${this.getType()}`})
      .success( this.handleDelete )
      .error(OX.Alert.display);
  }

  isEnabled() {
    return this.$el.closest('.enabled-providers').length !== 0;
  }

  moveToEnabledSection() {
    return this.$el.hide('fast', () => {
      $('.enabled-providers .providers').append(this.$el);
      return this.$el.show();
    });
  }

  moveToDisabledSection() {
    return this.$el.hide('fast', () => {
      $('.other-sign-in .providers').append(this.$el);
      return this.$el.show();
    });
  }

  add() {
    // TODO: figure out a way for the BE to pass the url
    return window.location.href = `${BASE_URL}/add/${this.getType()}`;
  }

  addNewflow() {
    return window.location.href = `${BASE_URL}/i/auth/${this.getType()}`;
  }

  handleDelete(response) {
    if (response.location != null) {
      return window.location.href = response.location;
    } else {
      return this.moveToDisabledSection();
    }
  }
}

class Password extends AuthenticationOption {

  constructor(el) {
    super(...arguments);
    this.el = el;
    this.$el.find('.edit').click(this.editPassword);
    this.$el.find('.edit--newflow').click(this.editPasswordNewflow);
    this.$el.find('.add--newflow').click(this.addPasswordNewflow);
  }

  // TODO we should just use normal links for edit and add, instead of these JS handlers

  editPassword() {
    return window.location.href = `${BASE_URL}/password/reset`;
  }

  editPasswordNewflow() {
    return window.location.href = `${BASE_URL}/i/change_password_form`;
  }

  add() {
    return window.location.href = `${BASE_URL}/password/add`;
  }

  addPasswordNewflow() {
    return window.location.href = `${BASE_URL}/i/change_password_form`;
  }
}

const SPECIAL_TYPES =
  {identity: Password};

OX.Profile.Authentication = {

  initialize() {
    return $('.authentication').each(function(i, el) {
      const klass = SPECIAL_TYPES[$(el).data('provider')] || AuthenticationOption;
      return new klass(el);
    });
  }

};
}).call(this);
