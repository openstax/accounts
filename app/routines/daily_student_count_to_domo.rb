require 'pg'
require 'net/http'
require 'base64'

class DailyStudentCountToDomo

  def self.call
    new.call
  end

  def call
    info('starting')
    begin
      query_date = Date.today - 1
      results = User.where('role = :role and created_at = :query_date',{ role: 1, query_date: (Time.now - 1.day).strftime("%Y/%m/%d")}).count
      query_results = query_date.strftime('%Y/%m/%d') + ', ' + results.inspect

      # update dataset in domo
      send_data_to_domo(query_results)
    rescue => e
      Raven.capture_message('DailyStudentCountToDomo: Error running query and updating Domo')
      Raven.capture_exception(e)
    end
  end

  def send_data_to_domo(query_results)
    access_token = get_access_token
    uri = URI.parse(Rails.application.secrets.domo[:domo_dataset_url])
    http_new = Net::HTTP.new(uri.host, uri.port)
    http_new.use_ssl = true
    request = Net::HTTP::Put.new(uri.request_uri)
    request['Authorization'] = 'bearer ' + access_token
    request['Content-Type'] = 'text/csv'
    request.body = query_results
    request['Accept'] = 'application/json'
    response = http_new.request request
    info('Finished! Data: ' + query_results + ' Response: ' + response.each_header.inspect)
  end

  def get_access_token
    # set header
    uri = URI.parse(Rails.application.secrets.domo[:domo_token_url])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    credentials = Base64.strict_encode64(Rails.application.secrets.domo[:domo_credentials])
    request['Authorization'] = 'Basic ' + credentials
    request['Accept'] = 'application/json'

    # request token
    response = http.request(request)

    # parse out token
    json = JSON.parse(response.body)
    json['access_token']
  end

  def info(message)
    Rails.logger.info("DailyStudentCountToDomo: " + message)
  end
end
