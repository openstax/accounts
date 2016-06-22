class OX.ConfirmationPopover

  constructor: (options) ->
    @options = _.defaults({}, options, {
      html: true,
      title: 'Are you sure?'
      placement: 'right'
      cancelText: 'Cancel'
      confirmText: 'OK'
      message: ''
    })
    # call after defaults are set since generateContent reads @options
    @options.content = $(@generateContent())
    popover = $(@options.target).popover(@options)
    popover.popover('show')
    @options.content.on('click', '.btn', (ev) ->
      popover.popover('destroy')
      isAbort = $(this).hasClass('confirm-dialog-btn-abort')
      cb = if isAbort then options.onCancel else options.onConfirm
      cb(ev) if cb
    )

  generateContent: ->
    """
      <div>
        <span class="message">#{@options.message}</span>
        <p class="button-group" style="margin-top: 10px; text-align: center;">
          <button type="button" class="btn btn-small confirm-dialog-btn-abort">#{@options.cancelText}</button>
          <button type="button" class="btn btn-small btn-danger confirm-dialog-btn-confirm">#{@options.confirmText}</button>
        </p>
      </div>
    """
