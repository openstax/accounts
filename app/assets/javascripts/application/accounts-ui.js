(function () {
    var Ui;

    Ui = (function () {
        return {
            disableButton: function (selector) {
                $(selector).attr('disabled', 'disabled');
                $(selector).addClass('ui-state-disabled ui-button-disabled');
                return $(selector).attr('aria-disabled', true);
            },
            enableButton: function (selector) {
                $(selector).removeAttr('disabled');
                $(selector).removeAttr('aria-disabled');
                $(selector).removeClass('ui-state-disabled ui-button-disabled');
                return $(selector).button();
            },
            renderAndOpenDialog: function (html_id, content, modal_options) {
                var modalDialog, modalHeight, userScreenHeight;
                if (modal_options == null) {
                    modal_options = {};
                }
                if ($('#' + html_id).exists()) {
                    $('#' + html_id).remove();
                }
                $("#application-body").append(content);
                $('#' + html_id).modal(modal_options);
                modalDialog = $('#' + html_id + ' .modal-dialog');
                modalHeight = modalDialog.outerHeight();
                userScreenHeight = window.outerHeight;
                if (modalHeight > userScreenHeight) {
                    return modalDialog.css('overflow', 'auto');
                } else {
                    return modalDialog.css('margin-top', (userScreenHeight / 2) - (modalHeight / 2));
                }
            },
            checkCheckedButton: function (targetSelector, sourceSelector) {
                if ($(sourceSelector).is(':checked')) {
                    return this.enableButton(targetSelector);
                } else {
                    return this.disableButton(targetSelector);
                }
            },
            enableOnChecked: function (targetSelector, sourceSelector) {
                return $(document).ready((function (_this) {
                    return function () {
                        if (!$(sourceSelector).is(':checked')) {
                            _this.disableButton(targetSelector);
                        }
                        return $(sourceSelector).on('click', function () {
                            return _this.checkCheckedButton(targetSelector, sourceSelector);
                        });
                    };
                })(this));
            },
            syntaxHighlight: function (code) {
                var json;
                json = typeof code === !'string' ? JSON.stringify(code, void 0, 2) : code;
                json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
                return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
                    var cls;
                    cls = 'number';
                    if (/^"/.test(match)) {
                        if (/:$/.test(match)) {
                            cls = 'key';
                        } else {
                            cls = 'string';
                        }
                    } else if (/true|false/.test(match)) {
                        cls = 'boolean';
                    } else if (/null/.test(match)) {
                        cls = 'null';
                    }
                    return '<span class="' + cls + '">' + match + '</span>';
                });
            }
        };
    })();

    if (this.Accounts == null) {
        this.Accounts = {};
    }

    this.Accounts.Ui = Ui;

}).call(this);
