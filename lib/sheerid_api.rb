require 'sheerid_api/request'
require 'sheerid_api/response'
require 'sheerid_api/null_response'

# Service object for interacting with SheerID's API
# docs found at: http://developer.sheerid.com/rest-api
module SheeridAPI
  BASE_URL = 'https://services.sheerid.com/rest/v2'

  # Extract name, city and state from SheerID response when possible
  # 1. \A       - Beginning of string
  # 2. (.*?)    - Capturing group for name can lazy match anything
  # 3. (?: \(   - Optional non-capturing group for city and state with open parenthesis
  # 4. ([^,)]+) - Capturing group for city can match anything without comma or close parenthesis
  # 5. (?:,     - Optional non-capturing group for state with a comma and whitespace
  # 6. ([^)]+)  - Capturing group for state can match anything without close parenthesis
  # 7. )?       - Close optional non-capturing group for state
  # 8. \))?     - Close optional non-capturing group for city and state
  # 9. \z       - End of string
  SHEERID_REGEX = /\A(.*?)(?: \(([^,)]+)(?:, ([^)]+))?\))?\z/

  def self.get_verification_details(verification_id)
    verification_id_details_url = "#{BASE_URL}/verification/#{verification_id}/details"
    Request.new(:get, verification_id_details_url).response
  end
end
