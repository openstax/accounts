OxAccount.Modal =  {

  html: (url) -> """
    <div class="modal fade" id="OxAccountModal">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
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

  display: (page) ->
    OxAccount.Remote.nextPage = page
    src = OxAccount.HOST + '/remote/iframe?parent=' + encodeURI(window.location.href)
    OxAccount.$(document.body).append(@html(src))
    $('#OxAccountModal').modal()
    $('#myModal').on('hidden.bs.modal', -> OxAccount.proxy = null )
    OxAccount.proxy = new Porthole.WindowProxy(src, "OxAccountIframe")
    OxAccount.proxy.addEventListener( (msg) ->
      OxAccount.Remote[name](args) for name, args of msg.data
    )


  setBodySize: (size) ->
    $('#OxAccountIframe').height(size.height)

}
