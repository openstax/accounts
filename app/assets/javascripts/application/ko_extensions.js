// From https://stackoverflow.com/a/21715390/392102
ko.bindingHandlers.initValue = {
    init: function(element, valueAccessor) {
        var value = valueAccessor();
        if (!ko.isWriteableObservable(value)) {
            throw new Error('Knockout "initValue" binding expects an observable.');
        }
        value(element.value);
    }
};

ko.bindingHandlers.initChecked = {
    init: function(element, valueAccessor) {
        var value = valueAccessor();
        if (!ko.isWriteableObservable(value)) {
            throw new Error('Knockout "initChecked" binding expects an observable.');
        }
        value(element.checked);
    }
};

ko.bindingHandlers.valueWithInit = {
    init: function(element, valueAccessor, allBindings, data, context) {
        ko.applyBindingsToNode(element, { initValue: valueAccessor() }, context);
        ko.applyBindingsToNode(element, { value: valueAccessor() }, context);
    }
};

ko.bindingHandlers.checkedWithInit = {
    init: function(element, valueAccessor, allBindings, data, context) {
        ko.applyBindingsToNode(element, { initChecked: valueAccessor() }, context);
        ko.applyBindingsToNode(element, { checked: valueAccessor() }, context);
    }
};
