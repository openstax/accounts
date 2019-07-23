require 'rails_helper'

# See
#   https://github.com/codeforamerica/ohana-api/blob/master/spec/support/request_helpers.rb#L9-L16
#   https://github.com/codeforamerica/ohana-api/blob/master/spec/api/cors_spec.rb

describe 'OPTIONS request', type: :request do

  it 'does not explode' do
    expect{
      options('/api/options',
        params: {},
        headers: {
          'HTTP_ORIGIN' => 'http://cors.example.com',
          'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => 'Content-Type',
          'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET',
          'REQUEST_METHOD' => 'OPTIONS'
        }
      )
    }.not_to raise_error
  end

end
