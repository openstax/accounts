require 'sheerid_api/request'
require 'sheerid_api/response'
require 'sheerid_api/null_response'

# Service object for interacting with SheerID's API
# docs found at: http://developer.sheerid.com/rest-api
module SheeridAPI
  BASE_URL = 'https://services.sheerid.com/rest/v2'

  def self.get_verification_details(verification_id)
    verification_id_details_url = "#{BASE_URL}/verification/#{verification_id}/details"
    Request.new(:get, verification_id_details_url).response
  end
end
