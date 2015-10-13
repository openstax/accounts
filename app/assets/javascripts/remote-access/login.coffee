OxAccount.Login = {
  # display: -> new OxAccount.$.Deferred( @._display )

  # _display: (resolve, reject) ->
  #   src = OxAccount.HOST +
  #     '/remote/iframe?parent=' +
  #     encodeURI(window.location.href)
  #   frame = """
  #     <iframe
  #       style="width: 450px; height: 400px; position: absolute; left: 45%; bottom: 40%;"
  #       id="OxAccountLogin"
  #       name="OxAccountLogin"
  #       src="#{src}">
  #       </iframe>
  #   """
  #   OxAccount.$(document.body).append(frame)
  #   OxAccount.proxy = new Porthole.WindowProxy(src, "OxAccountLogin")
  #   OxAccount.proxy.addEventListener( (msg) ->
  #     OxAccount.Remote[name](args) for name, args of msg.data
  #   )
}
