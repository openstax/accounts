(function() {
// The forms in this control are written with x-editable styling so that it looks
// similar to the other controls.

const BASE_URL = `${OX.url_prefix}/contact_infos`;

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

class Email {

  constructor(el) {
    this.el = el;
    _.bindAll(this, ...allMethodNames(this));
    this.$el = $(this.el);
    this.id = this.$el.attr('data-id');
    this.$toggle = this.$el.find('.email-entry__toggle');
    this.$controls = this.$el.find('.email-entry__controls');
    this.$toggle.on('click', this.toggleControls);
    this.$el.find('.searchable').change(this.saveSearchable);
    this.$el.find('.resend-confirmation').click(this.sendVerification);
    this.update();
  }

  update() {
    const delBtn = this.$el.find('.delete');
    delBtn.off('click', this.confirmDelete);
    if (this.isOnlyVerifiedEmail()) {
      return delBtn.hide();
    } else {
      return delBtn.on('click', this.confirmDelete);
    }
  }

  toggleSpinner(show) {
    return this.$el.find('.spinner').toggle(_.isBoolean(show) && show);
  }

  url(action) {
    return `${BASE_URL}/${this.id}` + ( action ? `/${action}` : '' );
  }

  sendVerification(ev) {
    ev.preventDefault();
    ev.target.disabled = true;
    return $.ajax({type: "PUT", url: this.url('resend_confirmation')})
      .success( resp => {
        return OX.Alert.display({message: resp.message, type: 'success', parentEl: this.$el});
      })
      .error( e => {
        OX.Alert.display(_.extend(e, {parentEl: this.$el}));
        return ev.target.disabled = false;
      });
  }

  saveSearchable(ev) {
    this.toggleSpinner(true);
    ev.target.disabled = true;
    const data = {is_searchable: ev.target.checked};
    return $.ajax({type: "PUT", url: this.url('set_searchable'), data})
      .success( resp => this.set(resp) )
      .error( e => {
        ev.target.checked = !ev.target.checked;
        return OX.Alert.display(_.extend(e, {parentEl: this.$el}));
      }).complete( () => {
        ev.target.disabled = false;
        return this.toggleSpinner(false);
      });
  }

  set(contact) {
    if (contact.id != null) {
      this.id = contact.id;
      this.$el.attr('data-id', contact.id);
    }
    if (contact.is_searchable != null) {
      return this.$el.find('.searchable').prop('checked', contact.is_searchable);
    }
  }

  isOnlyVerifiedEmail() {
    return this.$el.hasClass('verified') && !this.$el.siblings('.email-entry.verified').length;
  }

  confirmDelete(ev) {
    return new OX.ConfirmationPopover({
      title: '',
      message: OX.I18n.email.confirm_delete,
      target: ev.target,
      placement: 'top',
      onConfirm: this.delete
    });
  }

  delete() {
    this.toggleSpinner(true);
    return $.ajax({type: "DELETE", url: this.url()})
      .success( () => {
        this.$el.remove();
        return OX.Profile.Email.onDeleteEmail(this);
      })
      .error(OX.Alert.displayInsideElement(this.$el))
      .complete(this.toggleSpinner);
  }

  toggleControls(ev) {
    ev.preventDefault();
    const expanded = !this.$el.hasClass('is-open');
    if (expanded) {
      $('.email-entry.is-open').each(function() {
        $(this).removeClass('is-open');
        $(this).find('.email-entry__controls').attr('aria-hidden', true);
        $(this).find('.email-entry__toggle').attr('aria-expanded', false);
      });
    }
    this.$el.toggleClass('is-open', expanded);
    this.$toggle.attr('aria-expanded', expanded);
    this.$controls.attr('aria-hidden', !expanded);
  }
}

OX.Profile.Email = {

  initialize() {
    $('.email-entry').each(function(indx, el) {
      return $(el).data({email: new Email(this)});
    });
    return this.addEmail = $('#add-an-email').click( () => this.onAddEmail() );
  },

  onDeleteEmail() {
    return $('.info .email-entry').each((indx, el) => $(el).data().email.update());
  },

  onAddEmail() {
    this.addEmail.hide();
    let email = $('#email-template').children().clone().addClass('new');
    $('#add-an-email-editable').append(email);
    const input = $(email).find('.value');
    input.editable({
      url: BASE_URL,
      params(params) {
        return {
          'contact_info[type]': 'EmailAddress',
          'contact_info[value]': params.value
        };
      },
      ajaxOptions: {
        type: 'POST'
      }
    }).on('hidden', (e, reason) => {
      this.addEmail.show();
      if (reason !== 'save') { return email.remove(); }
    }).on('save', function(e, params){
      email.removeClass('new');
      // editable removes the parent element unless it's inside a defer ?
      _.defer(function() {
        input.editable('destroy');
        return input.text(params.response.contact_info.value);
      });
      email = new Email(email);
      return email.set(params.response.contact_info);
    });
    // no idea why the defer is needed, but it fails (silently!) without it
    return _.defer(function() {
      input.editable('show');
      const labelText = document.createTextNode('Add new email');
      const br = document.createElement('br');
      const label = document.querySelector('.email-entry.new label');
      label.prepend(br);
      return label.prepend(labelText);
    });
  }

};
}).call(this);
