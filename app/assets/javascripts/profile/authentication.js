// Converted from CoffeeScript by pulling from the browser after transpilation
// Online transpilers did not work correctly.

(function() {
  const BASE_URL = OX.url_prefix.toString();

  function activateAuthenticationButtons(el) {
    const $el = $(el);

    function moveToDisabledSection() {
      return $el.hide(
        'fast',
        function() {
          $('.other-sign-in .providers').append($el);
          $el.show();
        }
      );
    }

    function getType() {
      return $el.data('provider');
    }

    function handleDelete() {
      if (response.location != null) {
        window.location.href = response.location;
      } else {
        moveToDisabledSection();
      }
    }

    function doDelete() {
      $.ajax({
        type: "DELETE",
        url: BASE_URL + "/auth/" + (getType())
      }).success(handleDelete).error(OX.Alert.display);
    }

    function confirmDelete({target}) {
      return OX.showConfirmationPopover({
        title: '',
        message: OX.I18n.authentication.confirm_delete,
        target: target,
        placement: 'top',
        onConfirm: doDelete
      });
    }

    function doAdd() {
      window.location.href = BASE_URL + "/auth/" + (getType());
    }

    $el.find('.delete').click(confirmDelete);
    $el.find('.add').click(doAdd);
  }

  function activatePasswordButtons(el) {
    const $el = $(el);

    function editPassword() {
      window.location.href = BASE_URL + "/change_password_form";
    }

    const addPassword = editPassword;

    $el.find('.edit').click(editPassword);
    $el.find('.add').click(addPassword);
  }

  PASSWORD_PROVIDER = 'identity';

  OX.Profile.Authentication = {
    initialize() {
      $('.authentication').each(function(i, el) {
        const activator = $(el).data('provider') === PASSWORD_PROVIDER ?
          activatePasswordButtons : activateAuthenticationButtons;

        activator(el);
      });
      $('#enable-other-sign-in').click(function(e) {
        e.preventDefault();
        $(this).hide();
        $('.other-sign-in').slideToggle();
      });
    }
  };

}).call(this);
