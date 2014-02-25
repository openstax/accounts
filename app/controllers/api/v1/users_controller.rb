class Api::V1::UsersController < Api::V1::OauthBasedApiController

  doorkeeper_for :all

  resource_description do
    api_versions "v1"
    short_description 'TBD'
    description <<-EOS
      TBD
    EOS
  end

  api :GET, '/users/:id', 'Gets the specified User'
  description <<-EOS
  EOS
  def get
    # raise SecurityTransgression if current_user.is_anonymous?
  end

end