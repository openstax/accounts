// The forms in this control are written with x-editable styling so that it looks
// similar to the other controls.

// Converted by pulling from the browser after transpilation.
// Online transpilers made nicer code, but it wasn't correct.
(function() {
  const BASE_URL = `${Accounts.url_prefix}/contact_infos`;

  class Email {

    constructor(el) {
      this.el = el;
      _.bindAll(this, ...Object.getOwnPropertyNames(Email.prototype));
      this.$el = $(this.el);
      this.id = this.$el.attr('data-id');
      this.$el.find('.searchable').change(this.saveSearchable);
      this.$el.find('.resend-confirmation').click(this.sendVerification);
      this.$el.find('.email, .unconfirmed-warning').click(this.toggleProperties);
      this.update();
    }

    update() {
      const delBtn = this.$el.find('.delete');
      delBtn.off('click', this.confirmDelete);
      if (this.isOnlyVerifiedEmail()) {
        delBtn.hide();
      } else {
        delBtn.on('click', this.confirmDelete);
      }
    }

    toggleProperties() {
      this.$el.toggleClass('expanded');
    }

    toggleSpinner(show) {
      this.$el.find('.spinner').toggle(_.isBoolean(show) && show);
    }

    url(action) {
      return `${BASE_URL}/${this.id}` + ( action ? `/${action}` : '' );
    }

    sendVerification(ev) {
      ev.preventDefault();
      ev.target.disabled = true;
      return $.ajax({type: "PUT", url: this.url('resend_confirmation')})
        .success( resp => {
          Accounts.Alert.display({message: resp.message, type: 'success', parentEl: this.$el});
        })
        .error( e => {
          Accounts.Alert.display(_.extend(e, {parentEl: this.$el}));
          ev.target.disabled = false;
        });
    }

    saveSearchable(ev) {
      this.toggleSpinner(true);
      ev.target.disabled = true;
      const data = {is_searchable: ev.target.checked};

      $.ajax({type: "PUT", url: this.url('set_searchable'), data})
        .success( resp => this.set(resp) )
        .error( e => {
          ev.target.checked = !ev.target.checked;
          Accounts.Alert.display(_.extend(e, {parentEl: this.$el}));
        }).complete( () => {
          ev.target.disabled = false;
          this.toggleSpinner(false);
        });
    }

    set(contact) {
      if (contact.id != null) {
        this.id = contact.id;
        this.$el.attr('data-id', contact.id);
      }
      if (contact.is_searchable != null) {
        this.$el.find('.searchable').prop('checked', contact.is_searchable);
      }
    }

    isOnlyVerifiedEmail() {
      return this.$el.hasClass('verified') && !this.$el.siblings('.email-entry.verified').length;
    }

    confirmDelete(ev) {
      Accounts.showConfirmationPopover({
        title: '',
        message: Accounts.I18n.email.confirm_delete,
        target: ev.target,
        placement: 'top',
        onConfirm: this.delete
      });
    }

    delete() {
      this.toggleSpinner(true);
      $.ajax({type: "DELETE", url: this.url()})
        .success( () => {
          this.$el.remove();
          Accounts.Profile.Email.onDeleteEmail(this);
        })
        .error(Accounts.Alert.displayInsideElement(this.$el))
        .complete(this.toggleSpinner);
    }
  }

  Accounts.Email = {

    initialize() {
      $('.email-entry').each(function(indx, el) {
        $(el).data({email: new Email(this)});
      });
      return this.addEmail = $('#add-an-email').click( () => this.onAddEmail() );
    },

    onDeleteEmail() {
      $('.info .email-entry').each((indx, el) => $(el).data().email.update());
    },

    onAddEmail() {
      let email = $('#email-template').children().clone().addClass('new');
      const input = $(email).insertBefore(this.addEmail).find('.email .value');

      this.addEmail.hide();
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
        if (reason !== 'save') { email.remove(); }
      }).on('save', function(e, params){
        email.removeClass('new');
        // editable removes the parent element unless it's inside a defer ?
        _.defer(function() {
          input.editable('destroy');
          input.text(params.response.contact_info.value);
        });
        email = new Email(email);
        email.set(params.response.contact_info);
      });
      // no idea why the defer is needed, but it fails (silently!) without it
      _.defer(() => input.editable('show'));
    }

  };

}).call(this);
