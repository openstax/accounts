class TransferOmniauthInformation

  include Lev::Routine
  uses_routine AddEmailToUser

protected

  def exec(auth_data, user)
    info = case auth_data[:provider]
           when "facebook"
             FacebookOmniauthData.new(auth_data)
           when "identity"
             raise Unexpected
           when "twitter"
             TwitterOmniauthData.new(auth_data)
           when "google_oauth2"
             GoogleOmniauthData.new(auth_data)
           else
             raise IllegalArgument, "unknown auth provider: #{auth_data[:provider]}"
           end

    info.emails.each do |email|
      run(AddEmailToUser, email, user, {already_verified: true})
    end
  end

end
