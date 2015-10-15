# Methods defined here are considered part of the "public" api

OxAccount.displayLogin = ->
  # modal will return a promise
  return OxAccount.Modal.display('login', size: 'md')


OxAccount.displayProfile = ->
  # Loading the profile page will set the size to lg regardless,
  # setting it earlier avaoids a resize
  return OxAccount.Modal.display('profile', size: 'lg')
