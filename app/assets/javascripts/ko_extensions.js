// From https://stackoverflow.com/a/21715390/392102
ko.bindingHandlers.initValue = {
    init(element, valueAccessor) {
        const value = valueAccessor();
        if (!ko.isWriteableObservable(value)) {
            throw new Error('Knockout "initValue" binding expects an observable.');
        }
        value(element.value);
    }
};

ko.bindingHandlers.initChecked = {
    init(element, valueAccessor) {
        const value = valueAccessor();
        if (!ko.isWriteableObservable(value)) {
            throw new Error('Knockout "initChecked" binding expects an observable.');
        }
        value(element.checked);
    }
};

ko.bindingHandlers.valueWithInit = {
    init(element, valueAccessor, allBindings, data, context) {
        ko.applyBindingsToNode(element, { initValue: valueAccessor() }, context);
        ko.applyBindingsToNode(element, { value: valueAccessor() }, context);
    }
};

ko.bindingHandlers.checkedWithInit = {
    init(element, valueAccessor, allBindings, data, context) {
        ko.applyBindingsToNode(element, { initChecked: valueAccessor() }, context);
        ko.applyBindingsToNode(element, { checked: valueAccessor() }, context);
    }
};

ko.bindingHandlers.phoneNumber = {
  init(element, valueAccessor) {
    const value = valueAccessor();

    value(
      intlTelInput(element, {
        formatOnInit: true,
        preferredCountries: ['us', 'pl']
      })
    );
  }
};

// Custom binding for partial _password_control_group
// Controls toggling password visibility and the checkmark in the tooltip
ko.bindingHandlers.passwordWithToolTip = {
  init(element, valueAccessor) {
    const minPasswordLength = valueAccessor();
    const mode = ko.observable('password');
    const showShow = ko.computed(() => mode() === 'password');
    const pwval = ko.observable('');
    const pwSuccess = ko.computed(() => pwval().length >= minPasswordLength);
    const buttonEl = document.getElementById('password-show-hide-button');
    const inputEl = element.querySelector('input');
    const checkmarkEl = document.getElementById('password-requirements-checkmark');

    function switchVisibility() {
      mode(mode() === 'password' ? 'text' : 'password');
    }

    ko.applyBindingsToNode(inputEl, {
      textInput: pwval,
      attr: {type: mode}
    });
    ko.applyBindingsToNode(checkmarkEl, { css: {success: pwSuccess} } );
    ko.applyBindingsToNode(buttonEl, {
      click: switchVisibility,
      css: {'show-show': showShow}
    });
  }
};

ko.bindingHandlers.editable = {
  init (element, valueAccessor, _ab, _d, context) {
    const {defaults, ...editableArgs} = ko.unwrap(valueAccessor());

    Object.assign($.fn.editable.defaults, defaults);

    $(element).editable(editableArgs);
  }
};
