Ui = do () ->
  enableOnChecked: (targetSelector, sourceSelector) ->
    $(document).ready =>

      enable_disable_continue = () =>
        Accounts.Ui.checkCheckedButton(targetSelector, sourceSelector)

      setTimeout(enable_disable_continue, 500)

      $(sourceSelector).on 'click', =>
        Accounts.Ui.checkCheckedButton(targetSelector, sourceSelector)

this.Ui = Ui
