class Api::V1::CredentialsController < Api::V1::OauthBasedApiController

  doorkeeper_for :all

  def me
    raise SecurityTransgression if current_user.is_anonymous?
  end

end