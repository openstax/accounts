require 'oauth'


module SignedParameters

  def self.verify(params)
    base_string = OAuth::Helper.normalize(
      params.except(:controller, :action, :client_id, :signature)
    )
    secret_key = ::Doorkeeper::Application.find_by_uid!(params[:client_id]).secret
    signature = OpenSSL::HMAC.hexdigest('sha1', secret_key, base_string)

    if signature.blank? || signature != params[:signature] ||
       !(2.minutes.ago..2.minutes.from_now).cover?(Time.at(params[:timestamp].to_i))

      Rails.logger.warn "Invalid signature for trusted parameters!"
      return false
    end

    return true
  end

end
