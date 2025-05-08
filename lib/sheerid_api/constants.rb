module SheeridAPI
  module Constants
    AUTHORIZATION_HEADER = "Bearer #{Rails.application.secrets.sheerid_api_secret}"
    HEADERS = {
      'Authorization': AUTHORIZATION_HEADER,
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }.freeze
  end
end
