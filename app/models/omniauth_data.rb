class OmniauthData

  def initialize(auth_data)
    @auth_data = auth_data
  end

  # Return an array of verified email addresses
  def emails
    [@auth_data.try(:info).try(:email)].flatten.compact
  end

end