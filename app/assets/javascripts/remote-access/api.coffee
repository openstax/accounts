# Methods defined here are considered part of the "public" api

OxAccount.displayLogin = ->
  # modal will return a promise
  return OxAccount.Modal.display('login', size: 'md')
