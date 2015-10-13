OxAccount.Remote = {

  init: ->

  # cross frame communication is established and pages can be loaded
  iFrameReady: (status) ->
    if @nextPage
      @displayPage(@nextPage)
      @nextPage = null

  displayPage: (page) ->
    OxAccount.proxy.post(loadPage: page)

  # fired when remote page is loaded
  pageLoad: (page) ->
    # do something here - close dialog, etc

  pageResize: (size) ->
    OxAccount.Modal.setBodySize(size)
}
