NewflowUi = do () ->
  disableButton: (selector) ->
    $(selector).attr('disabled', 'disabled')
    $(selector).addClass('ui-state-disabled ui-button-disabled')
    $(selector).css({
        'background': '#ccc',
        'box-shadow': 'none',
        'color': '#666'
      })

  enableButton: (selector) ->
    $(selector).removeAttr('disabled')
    $(selector).removeClass('ui-state-disabled ui-button-disabled')
    $(selector).button()
    $(selector).css({ 'background': '', 'box-shadow': '', 'color': '' })

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

  checkCheckedButton: (targetSelector, sourceSelector) ->
    if $(sourceSelector).is(':checked')
      @enableButton(targetSelector)
    else
      @disableButton(targetSelector)

  enableOnChecked: (targetSelector, sourceSelector) ->
    $(document).ready =>

      enable_disable_continue = () =>
        this.checkCheckedButton(targetSelector, sourceSelector)

      setTimeout(enable_disable_continue, 500)

      $(sourceSelector).on 'click', =>
        this.checkCheckedButton(targetSelector, sourceSelector)

  focusOnFirstErrorItem: () ->
    $(document).ready =>
      document.querySelector('.has-error')?.focus()

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

  attachSchoolList: (selector) ->
    el = document.querySelector(selector)
    listEl = document.getElementById(el.getAttribute('list'))
    el.addEventListener('input', ({target}) ->
      value = target.value
      if (value.length > 3)
        fetchSchools(target.value, listEl)
      else
        listEl.innerHTML = ''
    )

schoolQueryUrl = 'https://openstax.org/apps/cms/api/salesforce/schools/?search='
fetchSchools = _.debounce(
  (query, listEl) ->
    fetch "#{schoolQueryUrl}#{query}", {method: "GET"}
    .then (r) -> r.json()
    .then (arr) -> arr.map (entry) => "<option value=\"#{entry.name}\"></option>)"
    .then (arr) -> listEl.innerHTML = arr.join '\n'
  500
)

this.NewflowUi = NewflowUi
