OxAccount.Modal =  {

  html: (url, options) -> """
    <div class="modal fade" id="OxAccountModal">
      <div class="modal-dialog modal-#{options.size || 'lg'}">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
             <h4 class="modal-title"></h4>
          </div>
          <div class="modal-body">
            <iframe
              src=#{url}
              style="width: 100%; height: 400px; border: 0"
              id="OxAccountIframe" name="OxAccountIframe">
            </iframe>
          </div>
        </div><!-- /.modal-content -->
      </div><!-- /.modal-dialog -->
    </div><!-- /.modal -->
    """

  setTitle: (title) ->
    $('#OxAccountModal .modal-title').html(title)

  display: (page, options) ->
    OxAccount.Remote.nextPage = page
    promise = new $.Deferred()
    src = OxAccount.serverAddress() + '/remote/iframe?parent=' + encodeURI(window.location.href)
    OxAccount.$(document.body).append(@html(src, options))
    $('#OxAccountModal')
      .on('shown.bs.modal', =>
        @connectAndNotify(promise, src)
      ).on('hidden.bs.modal', ->
        @remove()
        OxAccount.proxy = null
        OxAccount.trigger('modal:hidden')
      )
      .modal()
    return promise

  connectAndNotify: (promise, src) ->
    OxAccount.trigger('modal:shown')

    # once the page finishes loading we resolve the promise
    OxAccount.one('page:load', ->
      promise.resolve(OxAccount)
    )

    OxAccount.proxy = new Porthole.WindowProxy(src, "OxAccountIframe")
    OxAccount.proxy.addEventListener( (msg) ->
      OxAccount.Remote[name](args) for name, args of msg.data
    )
    return promise


  setBodySize: (size) ->
    $('#OxAccountIframe').height(size.height)

  setSize: (size) ->
    $('#OxAccountModal .modal-dialog')
      .removeClass('modal-lg modal-md modal-sm')
      .addClass("modal-#{size}")

}
