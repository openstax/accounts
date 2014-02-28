Ui = do () ->

  disableButton: (selector) ->
    $(selector).attr('disabled', 'disabled')
    $(selector).addClass('ui-state-disabled ui-button-disabled')
    $(selector).attr('aria-disabled', true)

  enableButton: (selector) ->
    $(selector).removeAttr('disabled')
    $(selector).removeAttr('aria-disabled')
    $(selector).removeClass('ui-state-disabled ui-button-disabled')
    $(selector).button()

  renderAndOpenDialog: (html_id, content, modal_options = {}) ->
    if $('#' + html_id).exists() then $('#' + html_id).remove()
    $("#application-body").append(content)
    $('#' + html_id).modal(modal_options)

    # Code to center the dialog
    modalDialog = $('#' + html_id + ' .modal-dialog')
    modalHeight = modalDialog.outerHeight()
    userScreenHeight = window.outerHeight

    if modalHeight > userScreenHeight
      modalDialog.css('overflow', 'auto'); #set to overflow if no fit
    else
      modalDialog.css('margin-top', #center it if it does fit
                      ((userScreenHeight / 2) - (modalHeight / 2)))

  enableOnChecked: (targetSelector, sourceSelector) ->
    $(document).ready =>
      @disableButton(targetSelector)

    $(sourceSelector).on 'click', =>
      if $(sourceSelector).is(':checked')
        @enableButton(targetSelector)
      else
        @disableButton(targetSelector)

  syntaxHighlight: (code) ->
    json = if typeof code is not 'string' then JSON.stringify(code, undefined, 2) else code

    json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

    return json.replace(
      /("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, 
      (match) ->
        cls = 'number'
        if (/^"/.test(match))
          if (/:$/.test(match))
            cls = 'key'
          else
            cls = 'string'
        else if (/true|false/.test(match))
          cls = 'boolean'
        else if (/null/.test(match))
          cls = 'null'
        
        return '<span class="' + cls + '">' + match + '</span>'
    )  


(exports = this).Accounts ?= {}
exports.Accounts.Ui = Ui