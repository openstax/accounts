window.Ui = {
  enableOnChecked(targetSelector, sourceSelector) {
    return $(document).ready(
      () => {
        const enable_disable_continue = () => {
          return Accounts.Ui.checkCheckedButton(targetSelector, sourceSelector);
        };

        setTimeout(enable_disable_continue, 500);

        $(sourceSelector).on('click', () => {
          return Accounts.Ui.checkCheckedButton(targetSelector, sourceSelector);
        });
      }
    );
  }
};
